

                                 

exec deplcontrol.dbo.dpsp_Status @gears_id = 57128

--deplcontrol.dbo.dpsp_Approve @gears_id = 57128, @runtype = 'auto', @DBA_override = 'y'
                                 
-- deplcontrol.dbo.dpsp_Cancel_Gears 57128

-- EXECUTE [gears].[dbo].[CloneTicket] @build_request_id = 57118 ,@perform_dupe = 1


exec DEPLcontrol.dbo.dpsp_update @gears_id = 57128
                                ,@start_dt = '20110708 16:21'


--Update Request Detail for a specific Gears ID:
exec DEPLcontrol.dbo.dpsp_update @gears_id = 57128
                                ,@detail_id = 1311612
                                --,@DBname = 'SoundtrackDB'
                                ,@status = 'cancelled'
