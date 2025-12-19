#!/bin/bash

# 获取输入参数
bam_folder="$1"  # BAM 文件夹路径
allowance="$2"   # 允许范围

# 创建结果文件
output_file="length_statistics.txt"
echo "Total Reads,Length Below Threshold,Insertions Greater than Allowance,Percentage Below Threshold" > "$output_file"

# 初始化超过50%比例的BAM文件计数器
over_threshold_count=0

# 遍历 BAM 文件
for bam_file in "$bam_folder"/*.bam; do
    echo "Processing BAM file: $bam_file"
    
    # 从文件名中提取 contig_ID 和参考序列的起点、终点
    filename=$(basename "$bam_file")
    IFS=':' read -r contig_id range <<< "$filename"  # 使用 ':' 分隔
    IFS='-' read -r start end <<< "${range%.bam}"    # 去掉 .bam 并用 '-' 分隔
    
    # 计算参考序列长度
    reference_length=$((end - start + 1))
    echo "Start: $start, End: $end, Reference Length: $reference_length"
    
    # 初始化计数器
    total_reads=0
    below_threshold=0

    # 提取 CIGAR 字段并计算
    samtools view "$bam_file" | while read -r line; do
        # 确保读取行的格式正确并有足够字段
        if [[ -n "$line" ]]; then
            cigar=$(echo "$line" | awk '{print $6}')  # 提取 CIGAR 字段
            if [[ -n "$cigar" ]]; then  # 确保 CIGAR 字段不为空
                ((total_reads++))  # 计数器自增

                # 计算 M 和 D 的总长度
                m_length=$(echo "$cigar" | grep -o '[0-9]*M' | awk '{sum += $1} END {print sum}')
                d_length=$(echo "$cigar" | grep -o '[0-9]*D' | awk '{sum += $1} END {print sum}')

                # 计算实际长度
                actual_length=$((m_length + d_length))
                
                # 检查长度是否不足
                threshold="$reference_length"

                if [ "$actual_length" -le "$threshold" ]; then
                    ((below_threshold++))  # 计数器自增
                fi
                
                # 计算不足阈值的 reads 占比
                if [ $total_reads -gt 0 ]; then
                percentage_below_threshold=$(echo "scale=2; ($below_threshold / $total_reads) * 100" | bc)
                else
                percentage_below_threshold=0
                fi

            fi
        fi
    # 输出统计信息
    echo "$total_reads,$below_threshold,$insertions_greater_than_allowance,$percentage_below_threshold%" >> "$output_file"
    echo "Processed $filename: Total Reads: $total_reads, Below Threshold: $below_threshold, Insertions Greater than Allowance: $insertions_greater_than_allowance, Percentage Below Threshold: $percentage_below_threshold%"

    done
    
    echo "$filename" >> "$output_file"

    # 检查比例是否超过50%
    if (( $(echo "$percentage_below_threshold > 50" | bc -l) )); then
        ((over_threshold_count++))  # 自增计数
    fi
done

# 提取含有 contig 的文件及其前一行
grep 'contig' -B 1 "$output_file" > summary.txt

# 输出超过50%比例的 BAM 文件数量
echo "Total BAM files with more than 50% reads below threshold: $over_threshold_count" >> "$output_file"
echo "Summary: $over_threshold_count BAM files have more than 50% reads below threshold."

echo "Statistics written to $output_file and summary written to summary.txt"
