# frozen_string_literal: true

#
# Cookbook Name:: resource_metrics_snmp
# Recipe:: snmp
#
# Copyright 2018, P. van der Velde
#

#
# SNMP PACKAGES
#

%w[snmp snmp-mibs-downloader].each do |pkg|
  apt_package pkg do
    action :install
  end
end

#
# DIRECTORIES
#

telegraf_snmp_directory = '/usr/share/snmp'
directory telegraf_snmp_directory do
  action :create
  group node['telegraf']['service_group']
  mode '0755'
  owner node['telegraf']['service_user']
end

telegraf_mib_directory = "#{telegraf_snmp_directory}/mibs"
directory telegraf_mib_directory do
  action :create
  group node['telegraf']['service_group']
  mode '0755'
  owner node['telegraf']['service_user']
end

#
# MIBS
#

remote_file "#{telegraf_mib_directory}/UBNT-MIB" do
  action :create
  group 'root'
  mode '0755'
  owner 'root'
  source 'http://dl.ubnt-ut.com/snmp/UBNT-MIB'
end

remote_file "#{telegraf_mib_directory}/UBNT-UniFi-MIB" do
  action :create
  group 'root'
  mode '0755'
  owner 'root'
  source 'http://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB'
end

# This one isn't from UBNT but from Frogfoot Networks for reasons here:
# https://community.ubnt.com/t5/UniFi-Feature-Requests/publish-SNMP-MIBs/idc-p/1606196#M5632
file "#{telegraf_mib_directory}/FROGFOOT-RESOURCES-MIB" do
  action :create
  content <<~MIB
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
  MIB
  group 'root'
  mode '0755'
  owner 'root'
end

#
# CONSUL-TEMPLATE FILES
#

consul_template_config_path = node['consul_template']['config_path']
consul_template_template_path = node['consul_template']['template_path']

telegraf_snpm_uap_template_file = 'telegraf_snmp_uap.ctmpl'
file "#{consul_template_template_path}/#{telegraf_snpm_uap_template_file}" do
  action :create
  content <<~CONFIG
    [[inputs.snmp]]
      agents = [
        {{range $index, $service := ls "config/environment/infrastructure/snmp/unifi/uap" }}{{if ne $index 0}},{{end}}"{{ .Value }}:161"{{end}}
      ]
      auth_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}'{{ .Data.password }}'{{ end }}{{ end }}
      auth_protocol = "SHA"
      name = "snmp.uap"
      priv_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}'{{ .Data.password }}'{{ end }}{{ end }}
      priv_protocol = "AES"
      sec_level = "authPriv"
      sec_name = '{{ keyOrDefault "config/environment/infrastructure/snmp/user" "this_is_not_a_valid_user" }}'
      version = 3

      ##
      ## System Details
      ##

      #  System name (hostname)
      [[inputs.snmp.field]]
        is_tag = true
        name = "name"
        oid = "RFC1213-MIB::sysName.0"

      #  System description
      [[inputs.snmp.field]]
        name = "description"
        oid = "RFC1213-MIB::sysDescr.0"

      #  System uptime
      [[inputs.snmp.field]]
        name = "uptime"
        oid = "HOST-RESOURCES-MIB::hrSystemUptime.0"

      #  UAP model
      [[inputs.snmp.field]]
        is_tag = true
        name = "model"
        oid = "UBNT-UniFi-MIB::unifiApSystemModel"

      #  UAP firmware version
      [[inputs.snmp.field]]
        is_tag = true
        name = "version"
        oid = "UBNT-UniFi-MIB::unifiApSystemVersion"

      ##
      ## Host Resources
      ##

      #  Number of user sessions
      [[inputs.snmp.field]]
        name = "users"
        oid = "HOST-RESOURCES-MIB::hrSystemNumUsers.0"

      #  Number of process contexts
      [[inputs.snmp.field]]
        name = "processes"
        oid = "HOST-RESOURCES-MIB::hrSystemProcesses.0"

      #  Total memory
      [[inputs.snmp.field]]
        name = "mem.total"
        oid = "FROGFOOT-RESOURCES-MIB::memTotal.0"

      #  Free memory
      [[inputs.snmp.field]]
        name = "mem.free"
        oid = "FROGFOOT-RESOURCES-MIB::memFree.0"

      #  Buffer memory
      [[inputs.snmp.field]]
        name = "mem.buffer"
        oid = "FROGFOOT-RESOURCES-MIB::memBuffer.0"

      #  Cache memory
      [[inputs.snmp.field]]
        name = "mem.cache"
        oid = "FROGFOOT-RESOURCES-MIB::memCache.0"

      #  Per-interface traffic, errors, drops
      [[inputs.snmp.table]]
        name = "snmp.uap.interfaces"
        oid = "IF-MIB::ifTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "IF-MIB::ifDescr"

      ##
      ## System Performance
      ##

      #  System load averages
      [[inputs.snmp.table]]
        name = "snmp.uap.load"
        oid = "FROGFOOT-RESOURCES-MIB::loadTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "FROGFOOT-RESOURCES-MIB::loadDescr"

      ##
      ## Interface Details & Metrics
      ##

      #  Wireless interfaces
      [[inputs.snmp.table]]
        name = "snmp.uap.interfaces.wireless"
        oid = "UBNT-UniFi-MIB::unifiRadioTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiRadioName"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiRadioRadio"

      #  BSS instances
      [[inputs.snmp.table]]
        name = "snmp.uap.virtualaccesspoints"
        oid = "UBNT-UniFi-MIB::unifiVapTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiVapName"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiVapRadio"

      #  Ethernet interfaces
      [[inputs.snmp.table]]
        name = "snmp.uap.interfaces.ethernet"
        oid = "UBNT-UniFi-MIB::unifiIfTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiIfName"

      [inputs.snmp.tags]
        influxdb_database = "system"
  CONFIG
  group 'root'
  mode '0550'
  owner 'root'
end

telegraf_snmp_uap_file = 'inputs_snmp_uap.conf'
file "#{consul_template_config_path}/telegraf_snmp_uap.hcl" do
  action :create
  content <<~HCL
    # This block defines the configuration for a template. Unlike other blocks,
    # this block may be specified multiple times to configure multiple templates.
    # It is also possible to configure templates via the CLI directly.
    template {
      # This is the source file on disk to use as the input template. This is often
      # called the "Consul Template template". This option is required if not using
      # the `contents` option.
      source = "#{consul_template_template_path}/#{telegraf_snpm_uap_template_file}"

      # This is the destination path on disk where the source template will render.
      # If the parent directories do not exist, Consul Template will attempt to
      # create them, unless create_dest_dirs is false.
      destination = "#{node['telegraf']['config_directory']}/#{telegraf_snmp_uap_file}"

      # This options tells Consul Template to create the parent directories of the
      # destination path if they do not exist. The default value is true.
      create_dest_dirs = false

      # This is the optional command to run when the template is rendered. The
      # command will only run if the resulting template changes. The command must
      # return within 30s (configurable), and it must have a successful exit code.
      # Consul Template is not a replacement for a process monitor or init system.
      command = "/bin/bash -c 'chown #{node['telegraf']['service_user']}:#{node['telegraf']['service_group']} #{node['telegraf']['config_directory']}/#{telegraf_snmp_uap_file} && systemctl restart #{node['telegraf']['service_name']}'"

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
  HCL
  group 'root'
  mode '0550'
  owner 'root'
end

telegraf_snpm_usw_template_file = 'telegraf_snmp_usw.ctmpl'
file "#{consul_template_template_path}/#{telegraf_snpm_usw_template_file}" do
  action :create
  content <<~CONFIG
    [[inputs.snmp]]
      agents = [
        {{range $index, $service := ls "config/environment/infrastructure/snmp/unifi/usw" }}{{if ne $index 0}},{{end}}"{{ .Value }}:161"{{end}}
      ]
      auth_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}'{{ .Data.password }}'{{ end }}{{ end }}
      auth_protocol = "SHA"
      name = "snmp.usw"
      priv_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}'{{ .Data.password }}'{{ end }}{{ end }}
      priv_protocol = "AES"
      sec_level = "authPriv"
      sec_name = '{{ keyOrDefault "config/environment/infrastructure/snmp/user" "this_is_not_a_valid_user" }}'
      version = 3

      ##
      ## System Details
      ##

      #  System name (hostname)
      [[inputs.snmp.field]]
        is_tag = true
        name = "name"
        oid = "RFC1213-MIB::sysName.0"

      #  System description
      [[inputs.snmp.field]]
        name = "description"
        oid = "RFC1213-MIB::sysDescr.0"

      #  System uptime
      [[inputs.snmp.field]]
        name = "uptime"
        oid = "HOST-RESOURCES-MIB::hrSystemUptime.0"

      #  UAP model
      [[inputs.snmp.field]]
        is_tag = true
        name = "model"
        oid = "UBNT-UniFi-MIB::unifiApSystemModel"

      #  UAP firmware version
      [[inputs.snmp.field]]
        is_tag = true
        name = "version"
        oid = "UBNT-UniFi-MIB::unifiApSystemVersion"

      ##
      ## Host Resources
      ##

      #  Total memory
      [[inputs.snmp.field]]
        name = "mem.total"
        oid = "FROGFOOT-RESOURCES-MIB::memTotal.0"

      #  Free memory
      [[inputs.snmp.field]]
        name = "mem.free"
        oid = "FROGFOOT-RESOURCES-MIB::memFree.0"

      #  Buffer memory
      [[inputs.snmp.field]]
        name = "mem.uffer"
        oid = "FROGFOOT-RESOURCES-MIB::memBuffer.0"

      #  Cache memory
      [[inputs.snmp.field]]
        name = "mem.cache"
        oid = "FROGFOOT-RESOURCES-MIB::memCache.0"

      #  Per-interface traffic, errors, drops
      [[inputs.snmp.table]]
        name = "snmp.usw.interfaces"
        oid = "IF-MIB::ifTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "IF-MIB::ifDescr"

      ##
      ## System Performance
      ##

      #  System load averages
      [[inputs.snmp.table]]
        name = "snmp.usw.load"
        oid = "FROGFOOT-RESOURCES-MIB::loadTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "FROGFOOT-RESOURCES-MIB::loadDescr"

      ##
      ## Interface Details & Metrics
      ##

      #  Ethernet interfaces
      [[inputs.snmp.table]]
        name = "snmp.usw.interfaces.ethernet"
        oid = "UBNT-UniFi-MIB::unifiIfTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiIfName"

      [inputs.snmp.tags]
        influxdb_database = "system"
  CONFIG
  group 'root'
  mode '0550'
  owner 'root'
end

telegraf_snmp_usw_file = 'inputs_snmp_usw.conf'
file "#{consul_template_config_path}/telegraf_snmp_usw.hcl" do
  action :create
  content <<~HCL
    # This block defines the configuration for a template. Unlike other blocks,
    # this block may be specified multiple times to configure multiple templates.
    # It is also possible to configure templates via the CLI directly.
    template {
      # This is the source file on disk to use as the input template. This is often
      # called the "Consul Template template". This option is required if not using
      # the `contents` option.
      source = "#{consul_template_template_path}/#{telegraf_snpm_usw_template_file}"

      # This is the destination path on disk where the source template will render.
      # If the parent directories do not exist, Consul Template will attempt to
      # create them, unless create_dest_dirs is false.
      destination = "#{node['telegraf']['config_directory']}/#{telegraf_snmp_usw_file}"

      # This options tells Consul Template to create the parent directories of the
      # destination path if they do not exist. The default value is true.
      create_dest_dirs = false

      # This is the optional command to run when the template is rendered. The
      # command will only run if the resulting template changes. The command must
      # return within 30s (configurable), and it must have a successful exit code.
      # Consul Template is not a replacement for a process monitor or init system.
      command = "/bin/bash -c 'chown #{node['telegraf']['service_user']}:#{node['telegraf']['service_group']} #{node['telegraf']['config_directory']}/#{telegraf_snmp_usw_file} && systemctl restart #{node['telegraf']['service_name']}'"

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
  HCL
  group 'root'
  mode '0550'
  owner 'root'
end

telegraf_snmp_usg_template_file = 'telegraf_snmp_usg.ctmpl'
file "#{consul_template_template_path}/#{telegraf_snmp_usg_template_file}" do
  action :create
  content <<~CONFIG
    [[inputs.snmp]]
      agents = [
        {{range $index, $service := ls "config/environment/infrastructure/snmp/unifi/usg" }}{{if ne $index 0}},{{end}}"{{ .Value }}:161"{{end}}
      ]
      auth_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}'{{ .Data.password }}'{{ end }}{{ end }}
      auth_protocol = "SHA"
      name = "snmp.usg"
      priv_password = {{ with secret "secret/environment/infrastructure/snmp/user" }}{{ if .Data.password }}'{{ .Data.password }}'{{ end }}{{ end }}
      priv_protocol = "AES"
      sec_level = "authPriv"
      sec_name = '{{ keyOrDefault "config/environment/infrastructure/snmp/user" "this_is_not_a_valid_user" }}'
      version = 3

      ##
      ## System Details
      ##

      #  System name (hostname)
      [[inputs.snmp.field]]
        is_tag = true
        name = "name"
        oid = "RFC1213-MIB::sysName.0"

      #  System description
      [[inputs.snmp.field]]
        name = "description"
        oid = "RFC1213-MIB::sysDescr.0"

      #  System uptime
      [[inputs.snmp.field]]
        name = "uptime"
        oid = "HOST-RESOURCES-MIB::hrSystemUptime.0"

      #  UAP model
      [[inputs.snmp.field]]
        is_tag = true
        name = "model"
        oid = "UBNT-UniFi-MIB::unifiApSystemModel"

      #  UAP firmware version
      [[inputs.snmp.field]]
        is_tag = true
        name = "version"
        oid = "UBNT-UniFi-MIB::unifiApSystemVersion"

      ##
      ## Host Resources
      ##

      #  Number of user sessions
      [[inputs.snmp.field]]
        name = "users"
        oid = "HOST-RESOURCES-MIB::hrSystemNumUsers.0"

      #  Number of process contexts
      [[inputs.snmp.field]]
        name = "processes"
        oid = "HOST-RESOURCES-MIB::hrSystemProcesses.0"

      #  Device Listing
      [[inputs.snmp.table]]
        name = "snmp.usg.devices"
        oid = "HOST-RESOURCES-MIB::hrDeviceTable"
        [[inputs.snmp.table.field]]
          oid = "HOST-RESOURCES-MIB::hrDeviceIndex"
          is_tag = true

      #  Total memory
      [[inputs.snmp.field]]
        name = "mem.total"
        oid = "FROGFOOT-RESOURCES-MIB::memTotal.0"

      #  Free memory
      [[inputs.snmp.field]]
        name = "mem.free"
        oid = "FROGFOOT-RESOURCES-MIB::memFree.0"

      #  Buffer memory
      [[inputs.snmp.field]]
        name = "mem.buffer"
        oid = "FROGFOOT-RESOURCES-MIB::memBuffer.0"

      #  Cache memory
      [[inputs.snmp.field]]
        name = "mem.cache"
        oid = "FROGFOOT-RESOURCES-MIB::memCache.0"

      #  Per-interface traffic, errors, drops
      [[inputs.snmp.table]]
        name = "snmp.usg.interfaces"
        oid = "IF-MIB::ifTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "IF-MIB::ifDescr"

      #  Per-interface high-capacity (HC) counters
      [[inputs.snmp.table]]
        name = "snmp.usg.interfaces.hc"
        oid = "IF-MIB::ifXTable"
        [[inputs.snmp.table.field]]
          oid = "IF-MIB::ifName"
          is_tag = true

      ##
      ## System Performance
      ##

      #  System load averages
      [[inputs.snmp.table]]
        name = "snmp.usg.load"
        oid = "FROGFOOT-RESOURCES-MIB::loadTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "FROGFOOT-RESOURCES-MIB::loadDescr"

      ##
      ## Interface Details & Metrics
      ##

      #  Ethernet interfaces
      [[inputs.snmp.table]]
        name = "snmp.usg.interfaces.ethernet"
        oid = "UBNT-UniFi-MIB::unifiIfTable"
        [[inputs.snmp.table.field]]
          is_tag = true
          oid = "UBNT-UniFi-MIB::unifiIfName"

      ##
      ## IP metrics
      ##
      #  System-wide IP metrics
      [[inputs.snmp.table]]
        index_as_tag = true
        name = "snmp.usg.ip"
        oid = "IP-MIB::ipSystemStatsTable"

      ##
      ## ICMP Metrics
      ##

      #  ICMP statistics
      [[inputs.snmp.table]]
        index_as_tag = true
        name = "snmp.usg.icmp"
        oid = "IP-MIB::icmpStatsTable"

      #  ICMP per-type statistics
      [[inputs.snmp.table]]
        index_as_tag = true
        name = "snmp.usg.icmp.msg"
        oid = "IP-MIB::icmpMsgStatsTable"

      ##
      ## UDP statistics
      ##

      #  Datagrams delivered to app
      [[inputs.snmp.field]]
        name = "udp.in.datagrams"
        oid = "UDP-MIB::udpInDatagrams.0"

      #  Datagrams received with no app
      [[inputs.snmp.field]]
        name = "udp.ports"
        oid = "UDP-MIB::udpNoPorts.0"

      #  Datagrams received with error
      [[inputs.snmp.field]]
        name = "udp.in.errors"
        oid = "UDP-MIB::udpInErrors.0"

      #  Datagrams sent
      [[inputs.snmp.field]]
        name = "udp.out.datagrams"
        oid = "UDP-MIB::udpOutDatagrams.0"

      ##
      ## TCP statistics
      ##

      #  Number of CLOSED -> SYN-SENT transitions
      [[inputs.snmp.field]]
        name = "tcp.open.active"
        oid = "TCP-MIB::tcpActiveOpens.0"

      #  Number of SYN-RCVD -> LISTEN transitions
      [[inputs.snmp.field]]
        name = "tcp.open.passive"
        oid = "TCP-MIB::tcpPassiveOpens.0"

      #  Number of SYN-SENT/RCVD -> CLOSED transitions
      [[inputs.snmp.field]]
        name = "tcp.attempt.fail"
        oid = "TCP-MIB::tcpAttemptFails.0"

      #  Number of ESTABLISHED/CLOSE-WAIT -> CLOSED transitions
      [[inputs.snmp.field]]
        name = "tcp.transition.esttoclosed"
        oid = "TCP-MIB::tcpEstabResets.0"

      #  Number of ESTABLISHED or CLOSE-WAIT
      [[inputs.snmp.field]]
        name = "tcp.conn.established"
        oid = "TCP-MIB::tcpCurrEstab.0"

      #  Number of segments received
      [[inputs.snmp.field]]
        name = "tcp.segments.rec"
        oid = "TCP-MIB::tcpInSegs.0"

      #  Number of segments sent
      [[inputs.snmp.field]]
        name = "tcp.segments.sent"
        oid = "TCP-MIB::tcpOutSegs.0"

      #  Number of segments retransmitted
      [[inputs.snmp.field]]
        name = "tcp.segments.retrans"
        oid = "TCP-MIB::tcpRetransSegs.0"

      #  Number of segments received with error
      [[inputs.snmp.field]]
        name = "tcp.segments.errors"
        oid = "TCP-MIB::tcpInErrs.0"

      #  Number of segments sent w/RST
      [[inputs.snmp.field]]
        name = "tcp.segments.rst"
        oid = "TCP-MIB::tcpOutRsts.0"

      ##
      ## IP routing statistics
      ##

      #  Number of valid routing entries
      [[inputs.snmp.field]]
        name = "ip.route.valid"
        oid = "IP-FORWARD-MIB::inetCidrRouteNumber.0"

      #  Number of valid entries discarded
      [[inputs.snmp.field]]
        name = "ip.route.entry.discard"
        oid = "IP-FORWARD-MIB::inetCidrRouteDiscards.0"

      #  Number of valid forwarding entries
      [[inputs.snmp.field]]
        name = "ip.route.forward"
        oid = "IP-FORWARD-MIB::ipForwardNumber.0"

      ##
      ## IP routing statistics
      ##
      # Number of valid routes discarded
      [[inputs.snmp.field]]
        name = "ip.route.discard"
          oid = "RFC1213-MIB::ipRoutingDiscards.0"

      [inputs.snmp.tags]
        influxdb_database = "system"
  CONFIG
  group 'root'
  mode '0550'
  owner 'root'
end

telegraf_snmp_usg_file = 'inputs_snmp_usg.conf'
file "#{consul_template_config_path}/telegraf_snmp_usg.hcl" do
  action :create
  content <<~HCL
    # This block defines the configuration for a template. Unlike other blocks,
    # this block may be specified multiple times to configure multiple templates.
    # It is also possible to configure templates via the CLI directly.
    template {
      # This is the source file on disk to use as the input template. This is often
      # called the "Consul Template template". This option is required if not using
      # the `contents` option.
      source = "#{consul_template_template_path}/#{telegraf_snmp_usg_template_file}"

      # This is the destination path on disk where the source template will render.
      # If the parent directories do not exist, Consul Template will attempt to
      # create them, unless create_dest_dirs is false.
      destination = "#{node['telegraf']['config_directory']}/#{telegraf_snmp_usg_file}"

      # This options tells Consul Template to create the parent directories of the
      # destination path if they do not exist. The default value is true.
      create_dest_dirs = false

      # This is the optional command to run when the template is rendered. The
      # command will only run if the resulting template changes. The command must
      # return within 30s (configurable), and it must have a successful exit code.
      # Consul Template is not a replacement for a process monitor or init system.
      command = "/bin/bash -c 'chown #{node['telegraf']['service_user']}:#{node['telegraf']['service_group']} #{node['telegraf']['config_directory']}/#{telegraf_snmp_usg_file} && systemctl restart #{node['telegraf']['service_name']}'"

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
  HCL
  group 'root'
  mode '0550'
  owner 'root'
end
