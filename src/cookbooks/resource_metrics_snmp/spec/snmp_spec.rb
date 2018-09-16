# frozen_string_literal: true

require 'spec_helper'

describe 'resource_metrics_snmp::snmp' do
  context 'installs the snmp tools' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'installs the snmp binary' do
      expect(chef_run).to install_apt_package('snmp')
    end

    it 'installs the snmp binary' do
      expect(chef_run).to install_apt_package('snmp-mibs-downloader')
    end
  end

  context 'copies the MIB files' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates the snmp directory' do
      expect(chef_run).to create_directory('/usr/share/snmp').with(
        group: 'telegraf',
        owner: 'telegraf',
        mode: '0755'
      )
    end

    it 'creates the mib directory' do
      expect(chef_run).to create_directory('/usr/share/snmp/mibs').with(
        group: 'telegraf',
        owner: 'telegraf',
        mode: '0755'
      )
    end

    it 'downloads the UBNT-MIB file' do
      expect(chef_run).to create_remote_file('/usr/share/snmp/mibs/UBNT-MIB').with(
        source: 'http://dl.ubnt-ut.com/snmp/UBNT-MIB'
      )
    end

    it 'downloads the UBNT-UniFi-MIB file' do
      expect(chef_run).to create_remote_file('/usr/share/snmp/mibs/UBNT-UniFi-MIB').with(
        source: 'http://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB'
      )
    end

    frogfoot_mib_content = <<~CONF
      FROGFOOT-RESOURCES-MIB

      -- -*- mib -*-

      DEFINITIONS ::= BEGIN

      -- Frogfoot Networks CC Resources MIB

      --
      -- The idea behind this is to measure usage of resources.
      -- It does not contain information about the system such as
      -- cpu/disk types, etc.
      --

      IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE, Integer32, Gauge32,
        enterprises
          FROM SNMPv2-SMI
        TEXTUAL-CONVENTION, DisplayString
          FROM SNMPv2-TC
        MODULE-COMPLIANCE, OBJECT-GROUP
          FROM SNMPv2-CONF;

      resources   MODULE-IDENTITY
        LAST-UPDATED "200407170000Z"
        ORGANIZATION "Frogfoot Networks"
        CONTACT-INFO
          "  Abraham van der Merwe

            Postal: Frogfoot Networks CC
                P.O. Box 23618
                Claremont
                Cape Town
                7735
                South Africa

            Phone: +27 82 565 4451
            Email: abz@frogfoot.net"
        DESCRIPTION
          "The MIB module to describe system resources."
        ::= { system 1 }


      frogfoot    OBJECT IDENTIFIER ::= { enterprises 10002 }
      servers      OBJECT IDENTIFIER ::= { frogfoot 1 }
      Fsystem      OBJECT IDENTIFIER ::= { servers 1 }
      resources               OBJECT IDENTIFIER ::= {Fsystem 1}

      memory      OBJECT IDENTIFIER ::= { resources 1 }
      swap      OBJECT IDENTIFIER ::= { resources 2 }
      storage      OBJECT IDENTIFIER ::= { resources 3 }
      load      OBJECT IDENTIFIER ::= { resources 4 }

      resMIB      OBJECT IDENTIFIER ::= { resources 31 }
      resMIBObjects  OBJECT IDENTIFIER ::= { resMIB 1 }
      resConformance  OBJECT IDENTIFIER ::= { resMIB 2 }

      resGroups    OBJECT IDENTIFIER ::= { resConformance 1 }
      resCompliances  OBJECT IDENTIFIER ::= { resConformance 2 }

      TableIndex ::= TEXTUAL-CONVENTION
        DISPLAY-HINT  "d"
        STATUS      current
        DESCRIPTION
          "A unique value, greater than zero. It is recommended
          that values are assigned contiguously starting from 1."
        SYNTAX      Integer32 (1..2147483647)

      --
      -- Memory statistics
      --

      memTotal    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Total usable physical memory (in KB)"
        ::= { memory 1 }

      memFree      OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Available physical memory (in KB)"
        ::= { memory 2 }

      memBuffer    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Physical memory used by buffers (in KB)"
        ::= { memory 3 }

      memCache    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Physical memory used for caching (in KB)"
        ::= { memory 4 }

      --
      -- Swap space statistics
      --

      swapTotal    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Total swap space size (in KB)"
        ::= { swap 1 }

      swapFree     OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Swap space still available (in KB)"
        ::= { swap 2 }

      --
      -- Disk space statistics
      --

      diskNumber    OBJECT-TYPE
        SYNTAX      Integer32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "The number of mounted disks present on this system."
        ::= { storage 1 }

      diskTable    OBJECT-TYPE
        SYNTAX      SEQUENCE OF DiskEntry
        MAX-ACCESS    not-accessible
        STATUS      current
        DESCRIPTION
          "A table of mounted disks on this system."
        ::= { storage 2 }

      diskEntry    OBJECT-TYPE
        SYNTAX      DiskEntry
        MAX-ACCESS    not-accessible
        STATUS      current
        DESCRIPTION
          "An entry containing management information applicable
          to a particular mounted disk on the system."
        INDEX { diskIndex }
        ::= { diskTable 1 }

      DiskEntry ::=
        SEQUENCE {
          diskIndex    TableIndex,
          diskDev      DisplayString,
          diskDir      DisplayString,
          diskFSType    INTEGER,
          diskTotal    Gauge32,
          diskFree    Gauge32
        }

      diskIndex    OBJECT-TYPE
        SYNTAX      TableIndex
        MAX-ACCESS    not-accessible
        STATUS      current
        DESCRIPTION
          "A unique value, greater than zero, for each disk on the
          system. It is recommended that values are assigned contiguously
          starting from 1."
        ::= { diskEntry 1 }

      diskDev      OBJECT-TYPE
        SYNTAX      DisplayString
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "A textual string containing the disk device name."
        ::= { diskEntry 2 }

      diskDir      OBJECT-TYPE
        SYNTAX      DisplayString
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "A textual string containing the disk mount point."
        ::= { diskEntry 3 }

      diskFSType    OBJECT-TYPE
        SYNTAX      INTEGER {
                  unknown(0),    -- Unknown File System
                  adfs(1),    -- Acorn Advanced Disc Filing System
                  affs(2),    -- Amiga Fast File System
                  coda(3),    -- CODA File System
                  cramfs(4),    -- cram File System for small storage (ROMs etc)
                  ext2(5),    -- Ext2 File System
                  hpfs(6),    -- OS/2 HPFS File System
                  iso9660(7),    -- ISO 9660 (CDROM) File System
                  jffs2(8),    -- Journalling Flash File System
                  jfs(9),      -- JFS File System
                  minix(10),    -- Minix File System
                  msdos(11),    -- FAT-based File Systems
                  ncpfs(12),    -- Novell Netware(tm) File System
                  nfs(13),    -- Network File Sharing Protocol
                  ntfs(14),    -- NTFS File System (Windows NT)
                  qnx4(15),    -- QNX4 File System
                  reiserfs(16),  -- ReiserFS Journalling File System
                  romfs(17),    -- ROM File System
                  smbfs(18),    -- Server Message Block (SMB) Protocol
                  sysv(19),    -- SystemV/V7/Xenix/Coherent File System
                  tmpfs(20),    -- Virtual Memory File System
                  udf(21),    -- UDF (DVD, CDRW, etc) File System
                  ufs(22),    -- UFS File System (SunOS, FreeBSD, etc)
                  vxfs(23),    -- VERITAS VxFS(TM) File System
                  xfs(24)      -- XFS (SGI) Journalling File System
                }
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "The type of file system present on the disk. This
          does not include fake file systems such as the proc file
          system, devfs, etc. Additional types may be assigned by
          Frogfoot Networks in the future."
        ::= { diskEntry 4 }

      diskTotal    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Total space on disk (in MB)"
        ::= { diskEntry 5 }

      diskFree    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "Disk space still available (in MB)"
        ::= { diskEntry 6 }

      --
      -- Load Average statistics
      --

      loadNumber    OBJECT-TYPE
        SYNTAX      Integer32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "The number of load averages stored in the
          load average table."
        ::= { load 1 }

      loadTable    OBJECT-TYPE
        SYNTAX      SEQUENCE OF LoadEntry
        MAX-ACCESS    not-accessible
        STATUS      current
        DESCRIPTION
          "Load average information."
        ::= { load 2 }

      loadEntry    OBJECT-TYPE
        SYNTAX      LoadEntry
        MAX-ACCESS    not-accessible
        STATUS      current
        DESCRIPTION
          "An entry containing load average information."
        INDEX { loadIndex }
        ::= { loadTable 1 }

      LoadEntry ::=
        SEQUENCE {
          loadIndex    TableIndex,
          loadDescr    DisplayString,
          loadValue    Gauge32
        }

      loadIndex    OBJECT-TYPE
        SYNTAX      TableIndex
        MAX-ACCESS    not-accessible
        STATUS      current
        DESCRIPTION
          "A unique value, greater than zero, for each
          load average stored."
        ::= { loadEntry 1 }

      loadDescr    OBJECT-TYPE
        SYNTAX      DisplayString
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "A description of each load average."
        ::= { loadEntry 2 }

      loadValue    OBJECT-TYPE
        SYNTAX      Gauge32
        MAX-ACCESS    read-only
        STATUS      current
        DESCRIPTION
          "The 1,5 and 10 minute load averages. These values are
          stored as a percentage of processor load."
        ::= { loadEntry 3 }

      --
      -- Compliance Statements
      --

      resCompliance  MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION
          "The compliance statement for SNMP entities which have
          system resources such as volatile and non-volatile
          storage."
        MODULE
          MANDATORY-GROUPS { resMemGroup, resSwapGroup, resDiskGroup, resLoadGroup }
          GROUP resMemGroup
          DESCRIPTION
            "This group is mandatory for those systems which have
            any form of volatile storage."
          GROUP resSwapGroup
          DESCRIPTION
            "This group is mandatory for those systems which have
            the ability to temporarily swap unused pages to disk."
          GROUP resDiskGroup
          DESCRIPTION
            "This group is mandatory for those systems which have
            any form of non-volatile storage."
          GROUP resLoadGroup
          DESCRIPTION
            "This group is mandatory for those systems which store
            any form of processor load average information."
        ::= { resCompliances 1 }

      resMemGroup   OBJECT-GROUP
        OBJECTS { memTotal, memFree, memBuffer, memCache }
        STATUS      current
        DESCRIPTION
          "A collection of objects providing information specific to
          volatile system storage."
        ::= { resGroups 1 }

      resSwapGroup  OBJECT-GROUP
        OBJECTS { swapTotal, swapFree }
        STATUS      current
        DESCRIPTION
          "A collection of objects providing information specific to
          storage used for swapping pages to disk."
        ::= { resGroups 2 }

      resDiskGroup  OBJECT-GROUP
        OBJECTS { diskNumber, diskDev, diskDir, diskFSType, diskTotal, diskFree }
        STATUS      current
        DESCRIPTION
          "A collection of objects providing information specific to
          non-volatile system storage."
        ::= { resGroups 3 }

      resLoadGroup  OBJECT-GROUP
        OBJECTS { loadNumber, loadDescr, loadValue }
        STATUS      current
        DESCRIPTION
          "A collection of objects providing information specific to
          processor load averages."
        ::= { resGroups 4 }
      END
    CONF
    it 'creates the FROGFOOT-RESOURCES-MIB file' do
      expect(chef_run).to create_file('/usr/share/snmp/mibs/FROGFOOT-RESOURCES-MIB')
        .with_content(frogfoot_mib_content)
        .with(
          group: 'root',
          owner: 'root',
          mode: '0755'
        )
    end
  end

  context 'adds the consul-template files' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    telegraf_snmp_template_content = <<~CONF
      [[inputs.snmp]]
        agents = [
          {{range $index, $service := ls "config/environment/infrastructure/snmp/unifi/uap" }}{{if ne $index 0}},{{end}}"{{ .Value }}:161"{{end}}
        ]
        auth_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}"{{ .Data.password }}"{{ end }}{{ end }}
        auth_protocol = "SHA"
        name = "snmp.uap"
        sec_level = "authNoPriv"
        sec_name = "{{ keyOrDefault "config/environment/infrastructure/snmp/user" "this_is_not_a_valid_user" }}"
        version = 3

        ##
        ## System Details
        ##

        #  System name (hostname)
        [[inputs.snmp.field]]
          is_tag = true
          name = "sysName"
          oid = "RFC1213-MIB::sysName.0"

        #  System vendor OID
        [[inputs.snmp.field]]
          name = "sysObjectID"
          oid = "RFC1213-MIB::sysObjectID.0"

        #  System description
        [[inputs.snmp.field]]
          name = "sysDescr"
          oid = "RFC1213-MIB::sysDescr.0"

        #  System contact
        [[inputs.snmp.field]]
          name = "sysContact"
          oid = "RFC1213-MIB::sysContact.0"

        #  System location
        [[inputs.snmp.field]]
          name = "sysLocation"
          oid = "RFC1213-MIB::sysLocation.0"

        #  System uptime
        [[inputs.snmp.field]]
          name = "sysUpTime"
          oid = "RFC1213-MIB::sysUpTime.0"

        #  UAP model
        [[inputs.snmp.field]]
          name = "unifiApSystemModel"
          oid = "UBNT-UniFi-MIB::unifiApSystemModel"

        #  UAP firmware version
        [[inputs.snmp.field]]
          name = "unifiApSystemVersion"
          oid = "UBNT-UniFi-MIB::unifiApSystemVersion"

        ##
        ## Host Resources
        ##

        #  Total memory
        [[inputs.snmp.field]]
          name = "memTotal"
          oid = "FROGFOOT-RESOURCES-MIB::memTotal.0"

        #  Free memory
        [[inputs.snmp.field]]
          name = "memFree"
          oid = "FROGFOOT-RESOURCES-MIB::memFree.0"

        #  Buffer memory
        [[inputs.snmp.field]]
          name = "memBuffer"
          oid = "FROGFOOT-RESOURCES-MIB::memBuffer.0"

        #  Cache memory
        [[inputs.snmp.field]]
          name = "memCache"
          oid = "FROGFOOT-RESOURCES-MIB::memCache.0"

        #  Per-interface traffic, errors, drops
        [[inputs.snmp.table]]
          oid = "IF-MIB::ifTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "IF-MIB::ifDescr"

        ##
        ## System Performance
        ##

        #  System load averages
        [[inputs.snmp.table]]
          oid = "FROGFOOT-RESOURCES-MIB::loadTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "FROGFOOT-RESOURCES-MIB::loadDescr"

        ##
        ## SNMP metrics
        ##

        #  Number of SNMP messages received
        [[inputs.snmp.field]]
          name = "snmpInPkts"
          oid = "SNMPv2-MIB::snmpInPkts.0"

        #  Number of SNMP Get-Request received
        [[inputs.snmp.field]]
          name = "snmpInGetRequests"
          oid = "SNMPv2-MIB::snmpInGetRequests.0"

        #  Number of SNMP Get-Next received
        [[inputs.snmp.field]]
          name = "snmpInGetNexts"
          oid = "SNMPv2-MIB::snmpInGetNexts.0"

        #  Number of SNMP objects requested
        [[inputs.snmp.field]]
          name = "snmpInTotalReqVars"
          oid = "SNMPv2-MIB::snmpInTotalReqVars.0"

        #  Number of SNMP Get-Response received
        [[inputs.snmp.field]]
          name = "snmpInGetResponses"
          oid = "SNMPv2-MIB::snmpInGetResponses.0"

        #  Number of SNMP messages sent
        [[inputs.snmp.field]]
          name = "snmpOutPkts"
          oid = "SNMPv2-MIB::snmpOutPkts.0"

        #  Number of SNMP Get-Request sent
        [[inputs.snmp.field]]
          name = "snmpOutGetRequests"
          oid = "SNMPv2-MIB::snmpOutGetRequests.0"

        #  Number of SNMP Get-Next sent
        [[inputs.snmp.field]]
          name = "snmpOutGetNexts"
          oid = "SNMPv2-MIB::snmpOutGetNexts.0"

        #  Number of SNMP Get-Response sent
        [[inputs.snmp.field]]
          name = "snmpOutGetResponses"
          oid = "SNMPv2-MIB::snmpOutGetResponses.0"

        ##
        ## Interface Details & Metrics
        ##

        #  Wireless interfaces
        [[inputs.snmp.table]]
          oid = "UBNT-UniFi-MIB::unifiRadioTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiRadioName"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiRadioRadio"

        #  BSS instances
        [[inputs.snmp.table]]
          oid = "UBNT-UniFi-MIB::unifiVapTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiVapName"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiVapRadio"

        #  Ethernet interfaces
        [[inputs.snmp.table]]
          oid = "UBNT-UniFi-MIB::unifiIfTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiIfName"

      [inputs.snmp.tagpass]
        influxdb_database = "system"


      [[inputs.snmp]]
        agents = [
          {{range $index, $service := ls "config/environment/infrastructure/snmp/unifi/usw" }}{{if ne $index 0}},{{end}}"{{ .Value }}:161"{{end}}
        ]
        auth_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}"{{ .Data.password }}"{{ end }}{{ end }}
        auth_protocol = "SHA"
        name = "snmp.usw"
        sec_level = "authNoPriv"
        sec_name = "{{ keyOrDefault "config/environment/infrastructure/snmp/user" "this_is_not_a_valid_user" }}"
        version = 3

        ##
        ## System Details
        ##

        #  System name (hostname)
        [[inputs.snmp.field]]
          is_tag = true
          name = "sysName"
          oid = "RFC1213-MIB::sysName.0"

        #  System vendor OID
        [[inputs.snmp.field]]
          name = "sysObjectID"
          oid = "RFC1213-MIB::sysObjectID.0"

        #  System description
        [[inputs.snmp.field]]
          name = "sysDescr"
          oid = "RFC1213-MIB::sysDescr.0"

        #  System contact
        [[inputs.snmp.field]]
          name = "sysContact"
          oid = "RFC1213-MIB::sysContact.0"

        #  System location
        [[inputs.snmp.field]]
          name = "sysLocation"
          oid = "RFC1213-MIB::sysLocation.0"

        #  System uptime
        [[inputs.snmp.field]]
          name = "sysUpTime"
          oid = "RFC1213-MIB::sysUpTime.0"

        #  UAP model
        [[inputs.snmp.field]]
          name = "unifiApSystemModel"
          oid = "UBNT-UniFi-MIB::unifiApSystemModel"

        #  UAP firmware version
        [[inputs.snmp.field]]
          name = "unifiApSystemVersion"
          oid = "UBNT-UniFi-MIB::unifiApSystemVersion"

        ##
        ## Host Resources
        ##

        #  Total memory
        [[inputs.snmp.field]]
          name = "memTotal"
          oid = "FROGFOOT-RESOURCES-MIB::memTotal.0"

        #  Free memory
        [[inputs.snmp.field]]
          name = "memFree"
          oid = "FROGFOOT-RESOURCES-MIB::memFree.0"

        #  Buffer memory
        [[inputs.snmp.field]]
          name = "memBuffer"
          oid = "FROGFOOT-RESOURCES-MIB::memBuffer.0"

        #  Cache memory
        [[inputs.snmp.field]]
          name = "memCache"
          oid = "FROGFOOT-RESOURCES-MIB::memCache.0"

        #  Per-interface traffic, errors, drops
        [[inputs.snmp.table]]
          oid = "IF-MIB::ifTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "IF-MIB::ifDescr"

        ##
        ## System Performance
        ##

        #  System load averages
        [[inputs.snmp.table]]
          oid = "FROGFOOT-RESOURCES-MIB::loadTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "FROGFOOT-RESOURCES-MIB::loadDescr"

        ##
        ## SNMP metrics
        ##

        #  Number of SNMP messages received
        [[inputs.snmp.field]]
          name = "snmpInPkts"
          oid = "SNMPv2-MIB::snmpInPkts.0"

        #  Number of SNMP Get-Request received
        [[inputs.snmp.field]]
          name = "snmpInGetRequests"
          oid = "SNMPv2-MIB::snmpInGetRequests.0"

        #  Number of SNMP Get-Next received
        [[inputs.snmp.field]]
          name = "snmpInGetNexts"
          oid = "SNMPv2-MIB::snmpInGetNexts.0"

        #  Number of SNMP objects requested
        [[inputs.snmp.field]]
          name = "snmpInTotalReqVars"
          oid = "SNMPv2-MIB::snmpInTotalReqVars.0"

        #  Number of SNMP Get-Response received
        [[inputs.snmp.field]]
          name = "snmpInGetResponses"
          oid = "SNMPv2-MIB::snmpInGetResponses.0"

        #  Number of SNMP messages sent
        [[inputs.snmp.field]]
          name = "snmpOutPkts"
          oid = "SNMPv2-MIB::snmpOutPkts.0"

        #  Number of SNMP Get-Request sent
        [[inputs.snmp.field]]
          name = "snmpOutGetRequests"
          oid = "SNMPv2-MIB::snmpOutGetRequests.0"

        #  Number of SNMP Get-Next sent
        [[inputs.snmp.field]]
          name = "snmpOutGetNexts"
          oid = "SNMPv2-MIB::snmpOutGetNexts.0"

        #  Number of SNMP Get-Response sent
        [[inputs.snmp.field]]
          name = "snmpOutGetResponses"
          oid = "SNMPv2-MIB::snmpOutGetResponses.0"

        ##
        ## Interface Details & Metrics
        ##

        #  Ethernet interfaces
        [[inputs.snmp.table]]
          oid = "UBNT-UniFi-MIB::unifiIfTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiIfName"

      [inputs.snmp.tagpass]
        influxdb_database = "system"


      [[inputs.snmp]]
        agents = [
          {{range $index, $service := ls "config/environment/infrastructure/snmp/unifi/usg" }}{{if ne $index 0}},{{end}}"{{ .Value }}:161"{{end}}
        ]
        auth_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}"{{ .Data.password }}"{{ end }}{{ end }}
        auth_protocol = "SHA"
        name = "snmp.usg"
        sec_level = "authNoPriv"
        sec_name = "{{ keyOrDefault "config/environment/infrastructure/snmp/user" "this_is_not_a_valid_user" }}"
        version = 3

        ##
        ## System Details
        ##

        #  System name (hostname)
        [[inputs.snmp.field]]
          is_tag = true
          name = "sysName"
          oid = "RFC1213-MIB::sysName.0"

        #  System vendor OID
        [[inputs.snmp.field]]
          name = "sysObjectID"
          oid = "RFC1213-MIB::sysObjectID.0"

        #  System description
        [[inputs.snmp.field]]
          name = "sysDescr"
          oid = "RFC1213-MIB::sysDescr.0"

        #  System contact
        [[inputs.snmp.field]]
          name = "sysContact"
          oid = "RFC1213-MIB::sysContact.0"

        #  System location
        [[inputs.snmp.field]]
          name = "sysLocation"
          oid = "RFC1213-MIB::sysLocation.0"

        #  System uptime
        [[inputs.snmp.field]]
          name = "sysUpTime"
          oid = "RFC1213-MIB::sysUpTime.0"

        #  UAP model
        [[inputs.snmp.field]]
          name = "unifiApSystemModel"
          oid = "UBNT-UniFi-MIB::unifiApSystemModel"

        #  UAP firmware version
        [[inputs.snmp.field]]
          name = "unifiApSystemVersion"
          oid = "UBNT-UniFi-MIB::unifiApSystemVersion"

        ##
        ## Host Resources
        ##

        #  Total memory
        [[inputs.snmp.field]]
          name = "memTotal"
          oid = "FROGFOOT-RESOURCES-MIB::memTotal.0"

        #  Free memory
        [[inputs.snmp.field]]
          name = "memFree"
          oid = "FROGFOOT-RESOURCES-MIB::memFree.0"

        #  Buffer memory
        [[inputs.snmp.field]]
          name = "memBuffer"
          oid = "FROGFOOT-RESOURCES-MIB::memBuffer.0"

        #  Cache memory
        [[inputs.snmp.field]]
          name = "memCache"
          oid = "FROGFOOT-RESOURCES-MIB::memCache.0"

        #  Per-interface traffic, errors, drops
        [[inputs.snmp.table]]
          oid = "IF-MIB::ifTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "IF-MIB::ifDescr"

            ##
        ## System Performance
        ##

        #  System load averages
        [[inputs.snmp.table]]
          oid = "FROGFOOT-RESOURCES-MIB::loadTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "FROGFOOT-RESOURCES-MIB::loadDescr"

        ##
        ## SNMP metrics
        ##

        #  Number of SNMP messages received
        [[inputs.snmp.field]]
          name = "snmpInPkts"
          oid = "SNMPv2-MIB::snmpInPkts.0"

        #  Number of SNMP Get-Request received
        [[inputs.snmp.field]]
          name = "snmpInGetRequests"
          oid = "SNMPv2-MIB::snmpInGetRequests.0"

        #  Number of SNMP Get-Next received
        [[inputs.snmp.field]]
          name = "snmpInGetNexts"
          oid = "SNMPv2-MIB::snmpInGetNexts.0"

        #  Number of SNMP objects requested
        [[inputs.snmp.field]]
          name = "snmpInTotalReqVars"
          oid = "SNMPv2-MIB::snmpInTotalReqVars.0"

        #  Number of SNMP Get-Response received
        [[inputs.snmp.field]]
          name = "snmpInGetResponses"
          oid = "SNMPv2-MIB::snmpInGetResponses.0"

        #  Number of SNMP messages sent
        [[inputs.snmp.field]]
          name = "snmpOutPkts"
          oid = "SNMPv2-MIB::snmpOutPkts.0"

        #  Number of SNMP Get-Request sent
        [[inputs.snmp.field]]
          name = "snmpOutGetRequests"
          oid = "SNMPv2-MIB::snmpOutGetRequests.0"

        #  Number of SNMP Get-Next sent
        [[inputs.snmp.field]]
          name = "snmpOutGetNexts"
          oid = "SNMPv2-MIB::snmpOutGetNexts.0"

        #  Number of SNMP Get-Response sent
        [[inputs.snmp.field]]
          name = "snmpOutGetResponses"
          oid = "SNMPv2-MIB::snmpOutGetResponses.0"

        ##
        ## Interface Details & Metrics
        ##

        #  Ethernet interfaces
        [[inputs.snmp.table]]
          oid = "UBNT-UniFi-MIB::unifiIfTable"
          [[inputs.snmp.table.field]]
            is_tag = true
            oid = "UBNT-UniFi-MIB::unifiIfName"

      [inputs.snmp.tagpass]
        influxdb_database = "system"
    CONF
    it 'creates telegraf snmp input template file in the consul-template template directory' do
      expect(chef_run).to create_file('/etc/consul-template.d/templates/telegraf_snmp.ctmpl')
        .with_content(telegraf_snmp_template_content)
        .with(
          group: 'root',
          owner: 'root',
          mode: '0550'
        )
    end

    consul_template_telegraf_snmp_content = <<~CONF
      # This block defines the configuration for a template. Unlike other blocks,
      # this block may be specified multiple times to configure multiple templates.
      # It is also possible to configure templates via the CLI directly.
      template {
        # This is the source file on disk to use as the input template. This is often
        # called the "Consul Template template". This option is required if not using
        # the `contents` option.
        source = "/etc/consul-template.d/templates/telegraf_snmp.ctmpl"

        # This is the destination path on disk where the source template will render.
        # If the parent directories do not exist, Consul Template will attempt to
        # create them, unless create_dest_dirs is false.
        destination = "/etc/telegraf/telegraf.d/inputs_snmp.conf"

        # This options tells Consul Template to create the parent directories of the
        # destination path if they do not exist. The default value is true.
        create_dest_dirs = false

        # This is the optional command to run when the template is rendered. The
        # command will only run if the resulting template changes. The command must
        # return within 30s (configurable), and it must have a successful exit code.
        # Consul Template is not a replacement for a process monitor or init system.
        command = "/bin/bash -c 'chown telegraf:telegraf /etc/telegraf/telegraf.d/inputs_snmp.conf && systemctl restart telegraf'"

        # This is the maximum amount of time to wait for the optional command to
        # return. Default is 30s.
        command_timeout = "30s"

        # Exit with an error when accessing a struct or map field/key that does not
        # exist. The default behavior will print "<no value>" when accessing a field
        # that does not exist. It is highly recommended you set this to "true" when
        # retrieving secrets from Vault.
        error_on_missing_key = false

        # This is the permission to render the file. If this option is left
        # unspecified, Consul Template will attempt to match the permissions of the
        # file that already exists at the destination path. If no file exists at that
        # path, the permissions are 0644.
        perms = 0550

        # This option backs up the previously rendered template at the destination
        # path before writing a new one. It keeps exactly one backup. This option is
        # useful for preventing accidental changes to the data without having a
        # rollback strategy.
        backup = true

        # These are the delimiters to use in the template. The default is "{{" and
        # "}}", but for some templates, it may be easier to use a different delimiter
        # that does not conflict with the output file itself.
        left_delimiter  = "{{"
        right_delimiter = "}}"

        # This is the `minimum(:maximum)` to wait before rendering a new template to
        # disk and triggering a command, separated by a colon (`:`). If the optional
        # maximum value is omitted, it is assumed to be 4x the required minimum value.
        # This is a numeric time with a unit suffix ("5s"). There is no default value.
        # The wait value for a template takes precedence over any globally-configured
        # wait.
        wait {
          min = "2s"
          max = "10s"
        }
      }
    CONF
    it 'creates telegraf_snmp.hcl in the consul-template template directory' do
      expect(chef_run).to create_file('/etc/consul-template.d/conf/telegraf_snmp.hcl')
        .with_content(consul_template_telegraf_snmp_content)
        .with(
          group: 'root',
          owner: 'root',
          mode: '0550'
        )
    end
  end
end
