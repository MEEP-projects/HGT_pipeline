#!/bin/bash

# 脚本输入参数
bed_file="$1"      # 插入区域的 BED 文件
bam_file="$2"      # 输入的 BAM 文件
flank_length="$3"  # flanking 区域长度
output_dir="$4"    # 输出目录

# 确保输出目录存在
mkdir -p "${output_dir}"

# 读取 BED 文件的每一行
while read -r line; do
    # 解析 BED 文件中的每个字段
    chrom=$(echo "$line" | cut -f 1)   # 染色体/contig 名称
    start=$(echo "$line" | cut -f 2)   # 插入区域的起始位置
    end=$(echo "$line" | cut -f 3)     # 插入区域的结束位置
    region_name=$(echo "$chrom:${start}-${end}")  # 用于文件命名的区域名

    # 计算带有 flanking 的区域范围
    new_start=$((start - flank_length)) # 插入区域前 flanking 区域
    new_end=$((end + flank_length))     # 插入区域后 flanking 区域

    # 确保坐标不会小于 0
    if [ "$new_start" -lt 0 ]; then
        new_start=0
    fi

    # 提取这个区域内的 reads
    output_bam="${output_dir}/${region_name}.bam"
    echo "提取区域 ${chrom}:${new_start}-${new_end} 到 ${output_bam}"

    # 使用 samtools 和 bedtools 提取指定区域的 reads
    samtools view -b "${bam_file}" "${chrom}:${new_start}-${new_end}" > "${output_bam}"

    # 为提取的 BAM 文件建立索引
    samtools index "${output_bam}"

done < "${bed_file}"

echo "所有插入区域及其 flanking reads 提取完成，结果保存至 ${output_dir}"
