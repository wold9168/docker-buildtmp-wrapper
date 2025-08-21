#!/bin/bash

# 复制用户配置文件脚本
# 将当前用户家目录下的配置文件复制到当前目录

set -e  # 遇到错误立即退出

# 获取当前脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOME_DIR="$HOME"

# 要复制的文件和目录列表
CONFIG_ITEMS=(
    ".oh-my-zsh"
    ".ssh"
    ".gnupg"
    ".gitconfig"
    ".bashrc"
    ".profile"
    ".zprofile"
    ".zshrc"
)

echo "开始复制用户配置文件..."
echo "源目录: $HOME_DIR"
echo "目标目录: $SCRIPT_DIR"
echo ""

# 计数器
copied_count=0
skipped_count=0

# 遍历并复制每个项目
for item in "${CONFIG_ITEMS[@]}"; do
    source_path="$HOME_DIR/$item"
    target_path="$SCRIPT_DIR/$item"
    if [ -e "$source_path" ]; then
        # echo "正在复制: $item"

        if [ -d "$source_path" ]; then
            # 复制目录 - 使用cp而不是rsync避免权限问题
            rsync -ar --delete "$source_path" "$SCRIPT_DIR/"
        else
            # 复制文件
            rsync -a --delete "$source_path" "$target_path"
        fi
        # echo "✓ 成功复制: $item"
    else
        echo "⚠ 跳过: $item (不存在)"
    fi
    # echo ""
done

echo "复制完成!"
