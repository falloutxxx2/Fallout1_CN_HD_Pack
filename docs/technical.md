# 技术说明

为什么这个包要这么大费周章：不是「复制几个文件」那么简单。

## 1. 中文是怎么来的

2007 年的简体中文补丁不改 `master.dat`，而是：

- 换掉主程序 `FALLOUTW.EXE`（1,245,696 字节），里面加了一段**字体 DLL 加载器**；
- 放一个 `fallout_font.dll`，里面是按 GBK 码位排好的中文点阵字模；
- 把 `DATA\TEXT\ENGLISH\` 下的 `.MSG` / `.TXT` 改写成「`{100}{}{中文}` + 被 `#` 注释掉的英文原文」；
- 覆盖 `DATA\art\intrface\` 里的 `.FRM`，让按钮和菜单里的字是中文图形。

所以补丁本体只有 8 MB，`master.dat` 保持 Steam 原版不动 —— 这也是为什么
「验证游戏文件完整性」只杀掉 `FALLOUTW.EXE`，其余中文还在（但已经没用了）。

## 2. 为什么要注入，而不是直接启动

`FALLOUTW.EXE` 的导入表里有一项 `SelectFont`，指向 `fallout_font.dll`。
原版流程是：主程序自己 `LoadLibrary` 这个 DLL，然后调用它。但配上 f1_res 的
**DX9 渲染器**（`GRAPHICS_MODE=2`）之后，渲染线程会在字体 DLL 就位之前就开始
绘制文字，跳到未初始化的导入槽 → 立刻 `0xc0000005`（模块 `unknown`），
窗口标题停在 `@640x480x1`。

解决办法就是启动器做的事：

1. `CreateProcess` 起游戏，**挂起观察**而不是等它自己加载；
2. 用 `CreateRemoteThread` + `LoadLibraryA` 把 `fallout_font.dll` 注入进去；
3. 轮询导入槽 `0x0053CFC0`，等到它不等于 `0` / `0xFFFFFFFF` 才算成功
   （日志里的 `fallout_font.dll pre-loaded, IAT filled.`）；
4. 失败就结束进程、把 ini 退回安全状态并提示改用 `Fallout_chinese.cmd`。

这个「像外挂」的行为会被杀毒软件盯上，所以 README 里提醒要放行 `powershell.exe`。

## 3. 两份 `f1_res.ini` 和 `path=`

f1_res 会读两份配置：

- 游戏目录下的 `f1_res.ini`；
- `%APPDATA%\Fallout\<一串哈希>\f1_res.ini`。

到底读哪份由 `UAC_AWARE` 决定：`UAC_AWARE=1` 时读 `%APPDATA%` 那份（为了在
UAC 虚拟化下也能写配置），`0` 时读游戏目录那份。

`%APPDATA%` 那份里有一行 `path=<游戏目录>`，是 f1_res 用来定位游戏数据的。
同一个 `%APPDATA%` 下可能有**好几个** `Fallout\<hash>\`（不同安装、不同版本各一份），
所以安装脚本和启动器都按这行 `path=` 去匹配：

- 只有 `path=` 指向**当前这个游戏目录**的那份才改；
- 别处安装的 ini 一个字节都不碰；
- 存在匹配项才写 `UAC_AWARE=1`，否则写 `0`（装到新机器、新路径时的正确行为）。

安装脚本还会把 `path=` 改写成实际安装路径。少了这一步，把包解到另一台机器的
`E:\...` 之后，f1_res 仍然会去找 `D:\...`，游戏起不来或者读错数据。

## 4. `GRAPHICS_MODE` 和「安全状态」

| 值 | 含义 |
|---|---|
| `0` | 基本模式：原版 640×480 渲染，全屏拉伸到 `SCR_WIDTH`×`SCR_HEIGHT` |
| `2` | f1_res 的 DX9 渲染：真高分、窗口化，**必须先注入字体 DLL** |

所以 ini 的默认值是 `GRAPHICS_MODE=0` + 1920×1440 全屏：这样即使有人直接点
Steam 的「开始游戏」（绕过启动器），也能进游戏看到中文，只是没有高清效果。
启动器运行时改成 `2`，退出时自动改回 `0`，不会留下「下次直接点 Steam 必定崩」的坑。

其它几个字段：`SCALE_2X=0`（1:1 原生像素，最清晰）、`COLOUR_BITS=32`、
`REFRESH_RATE=0`（跟随桌面）、`WIN_DATA=0`（不记忆窗口位置）、
`WINDOWED_FULLSCREEN`（无边框全屏）。

## 5. 备份与还原为什么按 manifest 而不是镜像

安装前不知道目标机器上哪些文件存在、哪些不存在（Steam 原版 vs 已打过别的补丁）。
所以 `backup\<时间戳>\manifest.json` 逐文件记录：

```json
{ "path": "DATA\\TEXT\\ENGLISH\\DIALOG\\BARRY.MSG", "existed": true }
```

- `existed: true` → 备份里存了原文件，卸载时复制回去；
- `existed: false` → 这个文件本来是安装脚本新建的，卸载时删掉。

镜像式还原（把整个备份目录覆盖回去）会把安装后才产生的存档、配置一起搞坏，
所以不用那种做法。文件复制前都会算 SHA256，相同就跳过 —— 幂等，重复安装不会
刷出一堆备份目录，也不会把已经正确的 ini 再写一遍。

## 6. 已知的限制

- 备份的是**安装那一刻**的文件状态。如果机器上本来就是打过补丁的状态，
  卸载只会回到「打过补丁」，回不到 Steam 原版 —— 那种情况请用
  Steam「验证游戏文件完整性」。
- 只测过 Steam 版目录结构（`steamapps\common\Fallout`）。
- 安卓模拟器占着 DirectInput 时游戏会弹 `Failure initializing input devices.`，
  这不是补丁的问题，关掉模拟器即可。
