awk '!seen[$0]++' common_source_codes.csv > tmp/common_source_codes.csv
mv tmp/common_source_codes.csv common_source_codes.csv
echo "DBeaver dupes removed from common_source_codes.csv"