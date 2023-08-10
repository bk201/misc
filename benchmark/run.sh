#!/bin/bash -e

DEVICE=$1

echo "Cleanup the page cache..."
echo 3 > /proc/sys/vm/drop_caches
sleep 10

echo "Start to benchmark raw device: $DEVICE"
echo "Start to 1M Sequential Write..."
fio --name=1M_SEQ_WRITE --ioengine=libaio --ramp_time=60 --filename=$DEVICE --rw=write --bs=1M --direct=1 --iodepth=32 --output=1M_seq_write.txt --output-format=normal,json

echo "Cleanup the page cache..."
echo 3 > /proc/sys/vm/drop_caches
sleep 10

echo "Start to 1M Sequential Read..."
fio --name=1M_SEQ_READ --ioengine=libaio --ramp_time=60 --filename=$DEVICE --rw=read --bs=1M --direct=1 --iodepth=32 --output=1M_seq_read.txt --output-format=normal,json

echo "Cleanup the page cache..."
echo 3 > /proc/sys/vm/drop_caches
sleep 10

echo "Start to 4k Random Read..."
fio --name=4K_RAND_READ --ioengine=libaio --ramp_time=60 --thread --random_generator=lfsr --cpus_allowed_policy=split --filename=$DEVICE --norandommap --rw=randread --bs=4k --direct=1 --iodepth=32 --numjobs=4 --group_reporting --output=4K_rand_read.txt --output-format=normal,json

echo "Cleanup the page cache..."
echo 3 > /proc/sys/vm/drop_caches
sleep 10

echo "Start to 4k Random Write..."
fio --name=4K_RAND_WRITE --ioengine=libaio --ramp_time=60 --thread --random_generator=lfsr --cpus_allowed_policy=split  --filename=$DEVICE --norandommap --rw=randwrite --bs=4k --direct=1 --iodepth=32 --numjobs=4 --group_reporting --output=4K_rand_write.txt --output-format=normal,json
