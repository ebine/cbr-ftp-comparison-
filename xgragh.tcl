set ns [new Simulator]
$ns color 1 Blue
$ns color 2 Red
set nf [open out.nam w]
$ns namtrace-all $nf
set nd [open out.tr w]
$ns trace-all $nd
set f0 [open cbr-throughput.tr w]
set f1 [open cbr-loss.tr w]
set f2 [open ftp-throughput.tr w]
set last_ack 0

proc record {} {
  global ns null tcp f0 f1 f2 last_ack
	set time 0.5 ;#Set Sampling Time to 0.5 Sec
	set a [$null set bytes_]
	set b [$null set nlost_]
	set c [$tcp set ack_]
	set d [$tcp set packetSize_]
	set now [$ns now]
	puts $f0 "$now [expr $a*8/$time]"
	puts $f1 "$now [expr $b/$time]"
	if { $c > 0 } {
		set e [expr $c - $last_ack]
		puts $f2 "$now [expr $e*$d*8/$time]"
		set last_ack $c
	} else {																													puts $f2 "$now 0"																									    }
	$null set bytes_ 0
	$null set nlost_ 0
    $ns at [expr $now+$time] "record"        ;# Schedule Record after $time interval sec
}
proc finish {} {																											  global ns nf nd f0 f1 f2
	$ns flush-trace	
	close $nf
	close $nd
	close $f0
    close $f1
	close $f2
	# Plot Recorded Statistics
	exec xgraph cbr-throughput.tr ftp-throughput.tr -geometry 800x400 &
	exec xgraph cbr-loss.tr -geometry 800x400 &
	# 以背景執行的方式去執行 NAM
	exec nam out.nam &
	exit 0
 }
 set s1 [$ns node]
 set s2 [$ns node]
 set r [$ns node]
 set d [$ns node]
 $ns duplex-link $s1 $r 2Mb 10ms DropTail
 $ns duplex-link $s2 $r 2Mb 10ms DropTail
 $ns duplex-link $r $d 1.7Mb 20ms DropTail
 # 設定 r 到 d 之間的 Queue Limit 為 10 個封包大小
 $ns queue-limit $r $d 10
 set tcp [new Agent/TCP]
 $ns attach-agent $s1 $tcp
 set sink [new Agent/TCPSink]
 $ns attach-agent $d $sink
 $ns connect $tcp $sink
 $tcp set fid_ 1
 set ftp [new Application/FTP]
 $ftp attach-agent $tcp
 $ftp set type_ FTP
 set udp [new Agent/UDP]
 $ns attach-agent $s2 $udp
 set null [new Agent/LossMonitor]
 $ns attach-agent $d $null
 $ns connect $udp $null
 $udp set fid_ 2
 set cbr [new Application/Traffic/CBR]
 $cbr attach-agent $udp
 $cbr set type_ CBR
 $cbr set packet_size_ 1000
 $cbr set rate_ 1mb
 $cbr set random_ false
 $ns  at 0.0 "record"
 $ns  at 0.1 "$cbr start"
 $ns  at 1.0 "$ftp start"
 $ns  at 4.0 "$ftp stop"
 $ns  at 4.5 "$cbr stop"
 $ns at 4.5 "$ns detach-agent $s1 $tcp ; $ns detach-agent $d $sink"
 $ns at 5.0 "finish"
 $ns run
