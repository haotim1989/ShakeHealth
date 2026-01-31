# 如何將 ShakeHealth 上傳至 GitHub

我已經幫您在本地端完成了 Git 初始化與第一次提交。請依照以下步驟將專案推送到 GitHub：

## 步驟 1：在 GitHub 建立新儲存庫
1. 登入 [GitHub](https://github.com)。
2. 點擊右上角「+」號 -> 選擇「New repository」。
3. **Repository name** 輸入 `ShakeHealth`。
4. 保持 Public 或 Private 皆可。
5. **不要** 勾選 "Add a README file", ".gitignore", "license" (本地已建立)。
6. 點擊 **Create repository**。

## 步驟 2：推送到 GitHub
打開終端機 (Terminal)，複製並執行以下指令 (請將 `<YOUR_USERNAME>` 換成您的 GitHub 帳號)：

```bash
cd "/Users/tienminhao/Desktop/Google Antigravity/Test_20260129_Drink/ShakeHealth"

# 1. 連結遠端儲存庫
git remote add origin https://github.com/<YOUR_USERNAME>/ShakeHealth.git

# 2. 推送程式碼
git branch -M main
git push -u origin main
```

## 日後更新方式
每次修改程式碼後，執行：

```bash
git add .
git commit -m "描述您的修改"
git push
```
