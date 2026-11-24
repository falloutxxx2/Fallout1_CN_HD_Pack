辐射 1（Steam 版）简体中文 + 高清补丁包
=================================================

这个包把 Steam 正版 Fallout 1 变成「简体中文 + 高清分辨率」版本，
一次安装，桌面得到两个快捷方式：

  Fallout 中文窗口   2560x1440 可移动窗口（1:1 原生像素，最清晰，推荐）
  Fallout 中文全屏   2560x1440 真全屏

包内容（files\ 下就是复制到游戏目录的文件）
-------------------------------------------------
   FALLOUTW.EXE              简体中文主程序（含 noword 写的字体 DLL 加载器）
  fallout_font.dll          GBK 中文点阵字体（noword）
  DATA\TEXT\ENGLISH\...     中文文本（对话/物品/界面，696 个 .MSG/.TXT）
  DATA\art\intrface\...     中文界面图形（38 个 .FRM）
  ddraw.dll  f1_res.dll     hi-res 补丁 f1_res（DirectDraw/DX9 渲染）
  f1_res.ini  f1_res_Config.exe  f1_res_patcher.exe  f1_res_README.rtf
  Fallout_chinese_windowed.cmd / .ps1   窗口/全屏启动器（负责提前加载字体 DLL）
  Fallout_chinese.cmd / .ps1            后备：基本模式全屏启动器

安装
-------------------------------------------------
  1. 关闭 Fallout 和 Steam 的游戏进程。
  2. 双击 install.cmd（会自动在 Steam 各库中找 ...\steamapps\common\Fallout）。
     找不到时：install.cmd -GameDir "D:\你的\Fallout"

     安装脚本会：
       - 把将被覆盖的原版文件备份到 backup\<日期时间>\（带 manifest.json）
       - 复制 files\ 里的全部文件
       - 把 f1_res.ini 设置为安全状态（基本模式 1920x1440 全屏）
       - 在桌面建立上面两个快捷方式

启动
-------------------------------------------------
  双击「Fallout 中文窗口」或「Fallout 中文全屏」。

  想换尺寸：右键快捷方式 - 属性 - 目标，在末尾加参数，例如
      -ClientWidth 1920 -ClientHeight 1080
      -Exclusive -ClientWidth 2560 -ClientHeight 1440

  直接点 Steam 里的「开始游戏」也能玩：走的是安全的基本模式
  （1920x1440 全屏，中文正常），但没有 DX9 高清渲染和窗口化。
  Steam 看不到启动器，所以高清窗口只能用桌面快捷方式。

卸载
-------------------------------------------------
  双击 uninstall.cmd：从最近的 backup\ 还原所有被覆盖的原版文件，
  并删除安装时新增的文件和两个快捷方式。
  指定某次备份：uninstall.cmd -Backup 20261124_015500
  保留快捷方式：uninstall.cmd -KeepShortcuts

注意事项
-------------------------------------------------
  * Steam「验证游戏文件完整性」会把英文原版 FALLOUTW.EXE 装回来，
    中文就没了；验证完再跑一次 install.cmd 即可。
  * 安卓模拟器（MuMu / 雷电 / 夜神 / BlueStacks）会抢占 DirectInput，
    可能让游戏弹 "Failure initializing input devices."。玩之前先关掉。
  * 分辨率与显示模式记录在 f1_res.ini（游戏目录和 %APPDATA%\Fallout\ 下各一份）。
    启动器每次运行都会重写这两份，退出时恢复成安全全屏状态。
  * 若杀毒软件拦截启动器（它对游戏进程做 CreateRemoteThread 注入），
    需要放行 fallout_chinese_windowed.ps1 所用的 powershell。

声明与致谢
-------------------------------------------------
  简体中文文本、中文字体与汉化主程序来自 13 号避难所（bn13.com）2007 年发布的
  《异尘余生汉化包》：程序 noword，译者、校对、测试的完整名单见上游仓库
  README 的「致谢」章节。原汉化包声明「版权归其开发者共同所有，
  未经许可，请勿用于任何商业目的」。
  Fallout 1 本身 © Bethesda Softworks / Interplay。
  hi-res 补丁 f1_res © 2008-2014 Matt Wells (Mash)，版本 4.1.8。
  本包只是把已装在作者本机的文件整理成可重复安装的形式，
  请仅用于你自己的正版备份，不要二次分发。
