String getNewTime(Duration time) =>
    "${time.inHours}:${time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${time.inSeconds.remainder(60).toString().padLeft(2, '0')}.${time.inMilliseconds.remainder(1000).toString().padLeft(3, '0').substring(0, 2)}";
