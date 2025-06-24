#!/bin/bash

# Always load .env file, supporting spaces in values
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found."
    exit 1
fi

if [ -z "$wow_addons_dir" ]; then
    echo "Error: wow_addons_dir is not set in the .env file."
    exit 1
fi

if [ -z "$wow_addons_dir_ptr" ]; then
    echo "Error: wow_addons_dir_ptr is not set in the .env file."
    exit 1
fi

# Locate .toc file
toc_file=$(find "$(pwd)" -name "*.toc" | head -n 1)
if [ -z "$toc_file" ]; then
    echo "Error: No .toc file found."
    exit 1
fi

addon_name=$(grep -oP '^## Title:\s*\K.*' "$toc_file" | tr -d '\r')
version=$(grep -oP '^## Version:\s*\K.*' "$toc_file" | tr -d '\r')

echo "Detected TOC file: $toc_file"
echo "Extracted Addon Name: '$addon_name'"
echo "Extracted Version: '$version'"

if [ -z "$addon_name" ] || [ -z "$version" ]; then
    echo "Error: Addon name or version not found in .toc file."
    exit 1
fi

./ci/scripts/package.sh

zip_file="ci/dist/${addon_name}-${version}.zip"
echo "Zip file will be: '$zip_file'"

local_deploy() {
    echo "Copying $zip_file to \"$wow_addons_dir/$addon_name\"..."
    mkdir -p "$wow_addons_dir/$addon_name"
    unzip -o "$zip_file" -d "$wow_addons_dir/$addon_name"
    echo "Done."
}

ptr_deploy() {
    echo "Copying $zip_file to \"$wow_addons_dir_ptr/$addon_name\"..."
    mkdir -p "$wow_addons_dir_ptr/$addon_name"
    unzip -o "$zip_file" -d "$wow_addons_dir_ptr/$addon_name"
    echo "Done."
}

local_deploy_classic() {
    echo "Copying $zip_file to \"$wow_addons_dir_classic/$addon_name\"..."
    mkdir -p "$wow_addons_dir_classic/$addon_name"
    unzip -o "$zip_file" -d "$wow_addons_dir_classic/$addon_name"
    echo "Done."
}

local_deploy_classic_era() {
    echo "Copying $zip_file to \"$wow_addons_dir_classic_era/$addon_name\"..."
    mkdir -p "$wow_addons_dir_classic_era/$addon_name"
    unzip -o "$zip_file" -d "$wow_addons_dir_classic/$addon_name"
    echo "Done."
}

if [ "$1" == "local" ] || [ "$1" == "lcl" ]; then
    local_deploy
elif [ "$1" == "ptr" ]; then
    ptr_deploy
elif [ "$1" == "era" ]; then
    local_deploy_classic_era
elif [ "$1" == "mop" ]; then
    local_deploy_classic
else
    echo "Error: Invalid argument. Use 'local' or 'lcl', 'era', 'mop' or 'ptr' to deploy."
    exit 1
fi