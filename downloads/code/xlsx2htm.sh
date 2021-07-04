#!/bin/bash
XLSX_DIR="E:/qqjy/plan/004 配置表"
OUT_DIR="E:/aaa"
cd "$XLSX_DIR"
XLSX_FILES=$(ls | grep xlsx | awk '{printf("%s:", $0)}')
i=1
while((1==1)); do
    file=$(echo $XLSX_FILES | cut -d ":" -f$i)
    i=$(expr $i + 1)
    if [ "$file" != "" ]; then
        echo "convert $file"
        soffice --headless --invisible --convert-to htm "$file" --outdir $OUT_DIR
    else
        break
    fi
done
