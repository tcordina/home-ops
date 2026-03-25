vrrp_script chk_haproxy {
    script "systemctl is-active haproxy"
    interval 2
    weight -20
}

vrrp_instance VI_1 {
    state ${vrrp_role}
    interface eth0
    virtual_router_id 51
    priority ${vrrp_priority}
    advert_int 1

    unicast_src_ip ${self_ip}
    unicast_peer {
        ${peer_ip}
    }

    authentication {
        auth_type PASS
        auth_pass k8shaproxy
    }

    virtual_ipaddress {
        ${vip}/24
    }

    track_script {
        chk_haproxy
    }
}
