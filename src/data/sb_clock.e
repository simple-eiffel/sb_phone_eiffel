note
	description: "System.currentTimeMillis, on the PC and on Android."
	author: "Larry Rix"

class
	SB_CLOCK

feature -- Access

	now: INTEGER_64
			-- Milliseconds since 1970.
		external
			"C inline use <time.h>"
		alias
			"[
				struct timespec l_time;
				#ifdef _WIN32
				timespec_get (&l_time, TIME_UTC);
				#else
				clock_gettime (CLOCK_REALTIME, &l_time);
				#endif
				return (EIF_INTEGER_64) l_time.tv_sec * 1000 + l_time.tv_nsec / 1000000;
			]"
		end

end
