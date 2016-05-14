resource clusterdb {
  protocol C;
  handlers {
    pri-on-incon-degr "/usr/lib/drbd/notify-pri-on-incon-degr.sh; /usr/lib/drbd/notify-emergency-reboot.sh; echo b > /proc/sysrq-trigger ; reboot -f";
    pri-lost-after-sb "/usr/lib/drbd/notify-pri-lost-after-sb.sh; /usr/lib/drbd/notify-emergency-reboot.sh; echo b > /proc/sysrq-trigger ; reboot -f";
    local-io-error "/usr/lib/drbd/notify-io-error.sh; /usr/lib/drbd/notify-emergency-shutdown.sh; echo o > /proc/sysrq-trigger ; halt -f";
    fence-peer "/usr/lib/drbd/crm-fence-peer.sh";
  }
  startup {
    degr-wfc-timeout 120;    # 2 minutes
    outdated-wfc-timeout 2;  # 2 seconds
  }
  disk {
    on-io-error detach;
  }
  net {
    cram-hmac-alg "sha1";
    shared-secret "clusterdb";
    after-sb-0pri disconnect;
    after-sb-1pri disconnect;
    after-sb-2pri disconnect;
    rr-conflict disconnect;
  }
  syncer {
    rate 10M;
    al-extents 257;
    on-no-data-accessible io-error;
  }
  on node1 {
    device /dev/drbd0;
    disk /dev/sdb;
    address 192.168.70.101:7788;
    flexible-meta-disk internal;
  }
  on node2 {
    device /dev/drbd0;
    disk /dev/sdb;
    address 192.168.70.102:7788;
    flexible-meta-disk internal;
  }
}