//----------------------------------------------------------------------
//	Test Stimuli
// Modified by Navis Shamszadeh to produce randomized input values for verification
//----------------------------------------------------------------------
initial begin : STIM
    wait (reset == 1);
    wait (reset == 0);
    GenerateRandomInputData(0);
    repeat(10) @(posedge clock);

    fork
        begin
            LoadInputData("input_random.txt");
            GenerateInputWave();
        	@(posedge clock);
            //LoadInputData("input5.txt");
            //GenerateInputWave();
        end
        begin
            compute_reference_dft();
        end
        begin
            wait (do_en == 1);
            repeat(N) @(posedge clock);
            SaveOutputData("output.txt");
            @(negedge clock);
            //wait (do_en == 1);
            //repeat(N) @(posedge clock);
            //SaveOutputData("output5.txt");
        end
    join
    $display("Simulation Completed.");
    compare_results();
    repeat(10) @(posedge clock);
    $finish;
end
