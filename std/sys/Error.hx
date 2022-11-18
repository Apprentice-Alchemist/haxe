package sys;

enum Error {
	/**
		The requested operation would be blocking.
		Try again later.
	**/
	Blocked;
	Unknown;
}