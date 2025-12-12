package llvm.libc;

enum abstract Errno(Int) {
	/* Operation not permitted */
	var EPERM = 1;
	/* No such file or directory */
	var ENOENT = 2;
	/* No such process */
	var ESRCH = 3;
	/* Interrupted system call */
	var EINTR = 4;
	/* I/O error */
	var EIO = 5;
	/* No such device or address */
	var ENXIO = 6;
	/* Argument list too long */
	var E2BIG = 7;
	/* Exec format error */
	var ENOEXEC = 8;
	/* Bad file number */
	var EBADF = 9;
	/* No child processes */
	var ECHILD = 10;
	/* Try again */
	var EAGAIN = 11;
	/* Out of memory */
	var ENOMEM = 12;
	/* Permission denied */
	var EACCES = 13;
	/* Bad address */
	var EFAULT = 14;
	/* Block device required */
	var ENOTBLK = 15;
	/* Device or resource busy */
	var EBUSY = 16;
	/* File exists */
	var EEXIST = 17;
	/* Cross-device link */
	var EXDEV = 18;
	/* No such device */
	var ENODEV = 19;
	/* Not a directory */
	var ENOTDIR = 20;
	/* Is a directory */
	var EISDIR = 21;
	/* Invalid argument */
	var EINVAL = 22;
	/* File table overflow */
	var ENFILE = 23;
	/* Too many open files */
	var EMFILE = 24;
	/* Not a typewriter */
	var ENOTTY = 25;
	/* Text file busy */
	var ETXTBSY = 26;
	/* File too large */
	var EFBIG = 27;
	/* No space left on device */
	var ENOSPC = 28;
	/* Illegal seek */
	var ESPIPE = 29;
	/* Read-only file system */
	var EROFS = 30;
	/* Too many links */
	var EMLINK = 31;
	/* Broken pipe */
	var EPIPE = 32;
	/* Math argument out of domain of func */
	var EDOM = 33;
	/* Math result not representable */
	var ERANGE = 34;

	/* Resource deadlock would occur */
	var EDEADLK = 35;
	/* File name too long */
	var ENAMETOOLONG = 36;
	/* No record locks available */
	var ENOLCK = 37;

	/*
	 * This error code is special: arch syscall entry code will return
	 * -ENOSYS if users try to call a syscall that doesn't exist.  To keep
	 * failures of syscalls that really do exist distinguishable from
	 * failures due to attempts to use a nonexistent syscall, syscall
	 * implementations should refrain from returning -ENOSYS.
	 */
	/* Invalid system call number */
	var ENOSYS = 38;

	/* Directory not empty */
	var ENOTEMPTY = 39;
	/* Too many symbolic links encountered */
	var ELOOP = 40;
	/* Operation would block */
	var EWOULDBLOCK = EAGAIN;
	/* No message of desired type */
	var ENOMSG = 42;
	/* Identifier removed */
	var EIDRM = 43;
	/* Channel number out of range */
	var ECHRNG = 44;
	/* Level 2 not synchronized */
	var EL2NSYNC = 45;
	/* Level 3 halted */
	var EL3HLT = 46;
	/* Level 3 reset */
	var EL3RST = 47;
	/* Link number out of range */
	var ELNRNG = 48;
	/* Protocol driver not attached */
	var EUNATCH = 49;
	/* No CSI structure available */
	var ENOCSI = 50;
	/* Level 2 halted */
	var EL2HLT = 51;
	/* Invalid exchange */
	var EBADE = 52;
	/* Invalid request descriptor */
	var EBADR = 53;
	/* Exchange full */
	var EXFULL = 54;
	/* No anode */
	var ENOANO = 55;
	/* Invalid request code */
	var EBADRQC = 56;
	/* Invalid slot */
	var EBADSLT = 57;
	/* Bad font file format */
	var EBFONT = 59;
	/* Device not a stream */
	var ENOSTR = 60;
	/* No data available */
	var ENODATA = 61;
	/* Timer expired */
	var ETIME = 62;
	/* Out of streams resources */
	var ENOSR = 63;
	/* Machine is not on the network */
	var ENONET = 64;
	/* Package not installed */
	var ENOPKG = 65;
	/* Object is remote */
	var EREMOTE = 66;
	/* Link has been severed */
	var ENOLINK = 67;
	/* Advertise error */
	var EADV = 68;
	/* Srmount error */
	var ESRMNT = 69;
	/* Communication error on send */
	var ECOMM = 70;
	/* Protocol error */
	var EPROTO = 71;
	/* Multihop attempted */
	var EMULTIHOP = 72;
	/* RFS specific error */
	var EDOTDOT = 73;
	/* Not a data message */
	var EBADMSG = 74;
	/* Bad CRC detected */
	var EFSBADCRC = EBADMSG;
	/* Value too large for defined data type */
	var EOVERFLOW = 75;
	/* Name not unique on network */
	var ENOTUNIQ = 76;
	/* File descriptor in bad state */
	var EBADFD = 77;
	/* Remote address changed */
	var EREMCHG = 78;
	/* Can not access a needed shared library */
	var ELIBACC = 79;
	/* Accessing a corrupted shared library */
	var ELIBBAD = 80;
	/* .lib section in a.out corrupted */
	var ELIBSCN = 81;
	/* Attempting to link in too many shared libraries */
	var ELIBMAX = 82;
	/* Cannot exec a shared library directly */
	var ELIBEXEC = 83;
	/* Illegal byte sequence */
	var EILSEQ = 84;
	/* Interrupted system call should be restarted */
	var ERESTART = 85;
	/* Streams pipe error */
	var ESTRPIPE = 86;
	/* Too many users */
	var EUSERS = 87;
	/* Socket operation on non-socket */
	var ENOTSOCK = 88;
	/* Destination address required */
	var EDESTADDRREQ = 89;
	/* Message too long */
	var EMSGSIZE = 90;
	/* Protocol wrong type for socket */
	var EPROTOTYPE = 91;
	/* Protocol not available */
	var ENOPROTOOPT = 92;
	/* Protocol not supported */
	var EPROTONOSUPPORT = 93;
	/* Socket type not supported */
	var ESOCKTNOSUPPORT = 94;
	/* Operation not supported on transport endpoint */
	var EOPNOTSUPP = 95;
	/* Protocol family not supported */
	var EPFNOSUPPORT = 96;
	/* Address family not supported by protocol */
	var EAFNOSUPPORT = 97;
	/* Address already in use */
	var EADDRINUSE = 98;
	/* Cannot assign requested address */
	var EADDRNOTAVAIL = 99;
	/* Network is down */
	var ENETDOWN = 100;
	/* Network is unreachable */
	var ENETUNREACH = 101;
	/* Network dropped connection because of reset */
	var ENETRESET = 102;
	/* Software caused connection abort */
	var ECONNABORTED = 103;
	/* Connection reset by peer */
	var ECONNRESET = 104;
	/* No buffer space available */
	var ENOBUFS = 105;
	/* Transport endpoint is already connected */
	var EISCONN = 106;
	/* Transport endpoint is not connected */
	var ENOTCONN = 107;
	/* Cannot send after transport endpoint shutdown */
	var ESHUTDOWN = 108;
	/* Too many references: cannot splice */
	var ETOOMANYREFS = 109;
	/* Connection timed out */
	var ETIMEDOUT = 110;
	/* Connection refused */
	var ECONNREFUSED = 111;
	/* Host is down */
	var EHOSTDOWN = 112;
	/* No route to host */
	var EHOSTUNREACH = 113;
	/* Operation already in progress */
	var EALREADY = 114;
	/* Operation now in progress */
	var EINPROGRESS = 115;
	/* Stale file handle */
	var ESTALE = 116;
	/* Structure needs cleaning */
	var EUCLEAN = 117;
	/* Filesystem is corrupted */
	var EFSCORRUPTED = EUCLEAN;
	/* Not a XENIX named type file */
	var ENOTNAM = 118;
	/* No XENIX semaphores available */
	var ENAVAIL = 119;
	/* Is a named type file */
	var EISNAM = 120;
	/* Remote I/O error */
	var EREMOTEIO = 121;
	/* Quota exceeded */
	var EDQUOT = 122;

	/* No medium found */
	var ENOMEDIUM = 123;
	/* Wrong medium type */
	var EMEDIUMTYPE = 124;
	/* Operation Canceled */
	var ECANCELED = 125;
	/* Required key not available */
	var ENOKEY = 126;
	/* Key has expired */
	var EKEYEXPIRED = 127;
	/* Key has been revoked */
	var EKEYREVOKED = 128;
	/* Key was rejected by service */
	var EKEYREJECTED = 129;

	/* for robust mutexes */
	/* Owner died */
	var EOWNERDEAD = 130;
	/* State not recoverable */
	var ENOTRECOVERABLE = 131;

	/* Operation not possible due to RF-kill */
	var ERFKILL = 132;

	/* Memory page has hardware error */
	var EHWPOISON = 133;
}
