//
//  PPViewController.m
//  DeviceInfo
//
//  Created by PAWAN POUDEL on 7/16/12.
//  Copyright (c) 2012 Mobile Defense Inc. All rights reserved.
//

/* Code borrowed heavily from iPhone Software Development site: http://iphonesdkdev.blogspot.com/2009/01/source-code-get-hardware-info-of-iphone.html
 
 Memory & CPU
 http://furbo.org/2007/08/21/what-the-iphone-specs-dont-tell-you/
 
 Process
 Landon Fuller, iphonesdk@googlegroups.com
 */

#import "PPViewController.h"

@interface PPViewController ()

@end

@implementation PPViewController

#import <stdio.h>
#import <string.h>

#import <mach/mach_host.h>
#import <sys/sysctl.h>

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

void printMemoryInfo()
{
    size_t length;
    int mib[6]; 
    int result;
    
    printf("Memory Info\n");
    printf("-----------\n");
    
    int pagesize;
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    length = sizeof(pagesize);
    if (sysctl(mib, 2, &pagesize, &length, NULL, 0) < 0)
    {
        perror("getting page size");
    }
    printf("Page size = %d bytes\n", pagesize);
    printf("\n");
    
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    
    vm_statistics_data_t vmstat;
    if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS)
    {
        printf("Failed to get VM statistics.");
    }
    
    double total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
    double wired = vmstat.wire_count / total;
    double active = vmstat.active_count / total;
    double inactive = vmstat.inactive_count / total;
    double free = vmstat.free_count / total;
    
    printf("Total =    %8d pages\n", vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count);
    printf("\n");
    printf("Wired =    %8d bytes\n", vmstat.wire_count * pagesize);
    printf("Active =   %8d bytes\n", vmstat.active_count * pagesize);
    printf("Inactive = %8d bytes\n", vmstat.inactive_count * pagesize);
    printf("Free =     %8d bytes\n", vmstat.free_count * pagesize);
    printf("\n");
    printf("Total =    %8d bytes\n", (vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count) * pagesize);
    printf("\n");
    printf("Wired =    %0.2f %%\n", wired * 100.0);
    printf("Active =   %0.2f %%\n", active * 100.0);
    printf("Inactive = %0.2f %%\n", inactive * 100.0);
    printf("Free =     %0.2f %%\n", free * 100.0);
    printf("\n");
    
    mib[0] = CTL_HW;
    mib[1] = HW_PHYSMEM;
    length = sizeof(result);
    if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
    {
        perror("getting physical memory");
    }
    printf("Physical memory = %8d bytes\n", result);
    mib[0] = CTL_HW;
    mib[1] = HW_USERMEM;
    length = sizeof(result);
    if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
    {
        perror("getting user memory");
    }
    printf("User memory =     %8d bytes\n", result);
    printf("\n");
}

void printProcessorInfo()
{
    size_t length;
    int mib[6]; 
    int result;
    
    printf("Processor Info\n");
    printf("--------------\n");
    
    mib[0] = CTL_HW;
    mib[1] = HW_CPU_FREQ;
    length = sizeof(result);
    if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
    {
        perror("getting cpu frequency");
    }
    printf("CPU Frequency = %d hz\n", result);
    
    mib[0] = CTL_HW;
    mib[1] = HW_BUS_FREQ;
    length = sizeof(result);
    if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
    {
        perror("getting bus frequency");
    }
    printf("Bus Frequency = %d hz\n", result);
    printf("\n");
}

int printProcessInfo() {
    int mib[5];
    struct kinfo_proc *procs = NULL, *newprocs;
    int i, st, nprocs;
    size_t miblen, size;
    
    /* Set up sysctl MIB */
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;
    mib[3] = 0;
    miblen = 4;
    
    /* Get initial sizing */
    st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    /* Repeat until we get them all ... */
    do {
        /* Room to grow */
        size += size / 10;
        newprocs = realloc(procs, size);
        if (!newprocs) {
            if (procs) {
                free(procs);
            }
            perror("Error: realloc failed.");
            return (0);
        }
        procs = newprocs;
        st = sysctl(mib, miblen, procs, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
    
    if (st != 0) {
        perror("Error: sysctl(KERN_PROC) failed.");
        return (0);
    }
    
    /* Do we match the kernel? */
    assert(size % sizeof(struct kinfo_proc) == 0);
    
    nprocs = size / sizeof(struct kinfo_proc);
    
    if (!nprocs) {
        perror("Error: printProcessInfo.");
        return(0);
    }
    printf("  PID\tName\n");
    printf("-----\t--------------\n");
    for (i = nprocs-1; i >=0;  i--) {
        printf("%5d\t%s\n",(int)procs[i].kp_proc.p_pid, procs[i].kp_proc.p_comm);
    }
    free(procs);
    return (0);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    printf("iPhone Hardware Info\n");
    printf("====================\n");
    printf("\n");
    
    printMemoryInfo();
    printProcessorInfo();
    printProcessInfo();    
}

@end
