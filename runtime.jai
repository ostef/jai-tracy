//
// Helpful macros to interface with the C api
//
#if ENABLED {
	#load "c_bindings.jai";

	profiler_running := false;

	IsRunning :: inline () -> bool #must {
		return profiler_running;
	}

	ToggleProfiler :: inline () {
		profiler_running = !profiler_running;
	}

	// Call this every frame.
	FrameMark :: () #expand #no_debug {
		if profiler_running {
			___tracy_emit_frame_mark(null);
		}
	}

	// Call this at the start of the scope you want to profile.
	ZoneScoped :: ($name := "", text := "", color: u32 = 0, value: u64 = 0) #expand #no_debug {
		tracy_ctx: TracyCZoneCtx;
		if profiler_running {
	        location := #location(#this);
			#if name {
				ZONE_NAME :: name;
			} else {
	            PROC_NAME :: #procedure_name(#this);
	            #if PROC_NAME {
	                ZONE_NAME :: PROC_NAME;
	            } else {
	                ZONE_NAME :: "<anonymous_procedure>";
	            }
			}

			tracy_loc := ___tracy_alloc_srcloc(xx location.line_number, location.fully_pathed_filename.data, xx location.fully_pathed_filename.count, ZONE_NAME.data, ZONE_NAME.count);
			tracy_ctx = ___tracy_emit_zone_begin_alloc(tracy_loc, 1);

			if text  ___tracy_emit_zone_text(tracy_ctx, text.data, cast(u64) text.count);
			if color ___tracy_emit_zone_color(tracy_ctx, color);
			if value ___tracy_emit_zone_value(tracy_ctx, value);
		}

		`defer if profiler_running {
			___tracy_emit_zone_end(tracy_ctx);
		}
	}

    #run {
        Compiler :: #import "Compiler";
        // Tracy requires these libs to work.
        #if OS == .WINDOWS {
            TRACY_DEPENDENCY_LIBS :: string.["ws2_32.lib", "msvcprtd.lib", "advapi32.lib", "user32.lib"];
        } else {
            TRACY_DEPENDENCY_LIBS :: string.["-lpthread", "-ldl", "-lc++"];
        }
        Compiler.set_build_options_dc(.{append_linker_arguments=TRACY_DEPENDENCY_LIBS});
    }
} else {

	IsRunning :: inline () -> bool #must { return false; }
	ToggleProfiler :: inline () {}
	FrameMark :: () #expand #no_debug {}
	ZoneScoped :: ($name := "", text := "", color: u32 = 0, value: u64 = 0, location := #caller_location) #expand #no_debug {}
}
