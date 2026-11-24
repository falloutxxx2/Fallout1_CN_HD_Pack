# 把这个仓库发到 GitHub

仓库内容已经在 `D:\Fallout1_CN_HD_Pack\` 整理好了（`.gitignore` 已把 `payload\`
排除在外）。下面三种方式任选一种，都不需要先懂 git。

推荐仓库名：`fallout1-cn-hd-pack`
建议 Topics：`fallout` `fallout1` `chinese` `simplified-chinese` `hi-res` `f1_res` `steam` `powershell`

---

## 方式 A：装 Git，命令行推（最干净，推荐）

```powershell
winget install --id Git.Git -e --source winget
```

装完**关掉当前终端重开**（让 PATH 生效），然后：

```powershell
cd D:\Fallout1_CN_HD_Pack
git init -b main
git add -A
git -c user.name="你的名字" -c user.email="你的邮箱" commit -m "Fallout 1 CN + hi-res patch pack: installer, uninstaller, launchers, docs"
```

在 GitHub 网页上 **New repository** → 名字 `fallout1-cn-hd-pack` → **不要**勾
Add a README / .gitignore / license（本地已经有了）→ Create，然后：

```powershell
git remote add origin https://github.com/<你的用户名>/fallout1-cn-hd-pack.git
git push -u origin main
```

第一次 push 会弹出浏览器让你登录 GitHub（Git Credential Manager）。

## 方式 B：网页上传，什么都不装

1. GitHub → **New repository** → 名字 `fallout1-cn-hd-pack` → Create。
2. 进仓库 → **Add file** → **Upload files**。
3. 打开资源管理器，进 `D:\Fallout1_CN_HD_Pack`，**打开「查看 → 显示隐藏的项目」**
   （不然 `.gitignore` / `.gitattributes` 看不见）。
4. 选中 `tools`、`docs`、`payload` 三个文件夹 + `README.md`、`README.txt`、
   `LICENSE`、`install.cmd`、`uninstall.cmd`、`build-release.ps1`、
   `.gitignore`、`.gitattributes`，一起拖进网页 → **Commit changes**。

`payload\` 只会上去一个 `README.md`（其余被 `.gitignore` 挡掉），这正是想要的。

## 方式 C：GitHub CLI，一条命令建库+推送

```powershell
winget install --id GitHub.cli -e --source winget
# 重开终端后：
gh auth login          # 选 GitHub.com → HTTPS → 浏览器登录
cd D:\Fallout1_CN_HD_Pack
git init -b main; git add -A
git commit -m "Fallout 1 CN + hi-res patch pack: installer, uninstaller, launchers, docs"
gh repo create fallout1-cn-hd-pack --public --source . --push
```

---

## 关于 Release（可选）

`build-release.ps1` 会用 `payload\` 打出 `Fallout1_CN_HD_Pack.zip`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
```

然后 GitHub → **Releases** → **Draft a new release** → tag `v1.0.0` → 把 zip 拖进附件。

> ⚠️ 附件里含第三方汉化文件（`FALLOUTW.EXE`、`fallout_font.dll`、中文文本与
> 界面图），属于别人的版权作品。公开分发有可能被 DMCA 下架或账号受限，
> 这一步要不要做、做到什么程度，你自己判断。仓库本身（只有脚本和文档）是安全的。

## 提交前自查

- [ ] `git status` 里看不到 `payload\` 下的 exe/dll/MSG/FRM（只有 `payload/README.md`）
- [ ] `.cmd` 仍是 CRLF 且纯 ASCII：`Format-Hex .\install.cmd | Select-Object -First 1`
      第一行应是 `40 65 63 68 6F 20 6F 66 66`（`@echo off`），没有 `EF BB BF`
- [ ] `.ps1` 保留 UTF-8 BOM（PowerShell 5.1 没 BOM 会把中文读成乱码）
- [ ] README 里的相对链接都指向真实文件（`payload/README.md`、`docs/technical.md`）
