ipset -N gfwlist iphash

ipset list gfwlist|tail -n +8|wc -l>/tmp/gfwlist_count_last
#ipset list gfwlist|tail -n +8|wc -l>/tmp/gfwlist_count

lastest=$(cat /tmp/gfwlist_count_last)
