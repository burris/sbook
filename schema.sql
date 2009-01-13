---
--- schema for Sync server
---
-- to restore a file:
--- mysql> SET FOREIGN_KEY_CHECKS = 0;
--- mysql> SOURCE your_dump_file;
--- mysql> SET FOREIGN_KEY_CHECKS = 1;
--

--- see http://perlwelt.horus.at/Beispiele/Magic/PerlUnicodeMysql/
--- mysql> SHOW CHARACTER SET;

create table users (
	userid int not null auto_increment, 	
	username varchar(32) not null,
	password_md5 varchar(32), 		
	modified timestamp, 			
	primary key (userid),
	key (username) 
) type=innodb charset=latin1;


create table entries (
	enteryid int not null auto_increment,
	userid int not null,
	modified timestamp,
	version int not null,
	gid varchar(255) not null,
	encrypted_entry blob(16777215),
	primary key (enteryid),
	key (userid),
	Foreign key (`userid`) references `users` (`userid`)
) type=innodb charset=utf8;

create table dellist (
	userid int not null,
	gid varchar(255) not null,
	deltime datetime,
	primary key (userid,gid),
	key (userid),
	key (deltime),
	Foreign key (`userid`) references `users` (`userid`)
) type=innodb charset=utf8;



	 
