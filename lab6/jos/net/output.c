#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";
  
	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
  int re;

  envid_t from_env;
  int perm;
  struct jif_pkt *pkt;

  while(1){
    re = ipc_recv(&from_env, &nsipcbuf, &perm);
    if(re != NSREQ_OUTPUT){
      continue;
    }
    
    pkt = &(nsipcbuf.pkt);
    while((sys_transmit_packet(pkt->jp_data, pkt->jp_len)) < 0){
      sys_yield(); 
    }
  
  } 
}
