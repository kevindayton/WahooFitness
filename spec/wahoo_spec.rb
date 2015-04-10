require 'spec_helper'
 
describe WahooFitness do
  
  before  do
    @file_paths = Array.new
    @file_strings = Hash.new  
    Dir.glob('example_files/*/*.csv') do |rb_file|
      @file_paths.push(rb_file)
      @file_strings[rb_file] = File.open(rb_file, "rb").read
    end
  end 
  
  describe "#new" do
    context "with filepath" do
      it "takes 1 parameters and returns a Wahoo object" do
        @file_paths.each do |path|
          puts "Testing #{path} as a filepath."
          wahoo = WahooFitness.new(path)
          expect(wahoo).to be_an_instance_of WahooFitness
        end
      end   
    end
    
    context "with string" do
      it "takes 2 parameters and returns a Wahoo object" do
        @file_strings.map do |k,v|
          puts "Testing #{k} as a string."
          wahoo = WahooFitness.new(v,false)
          expect(wahoo).to be_an_instance_of WahooFitness
        end
      end   
    end
  end

  describe "meta" do
    def test_meta_helper(meta)
      # Test Date 
        expect(meta["Year"]).not_to be_empty
        expect(meta["Month"]).not_to be_empty
        expect(meta["Day"]).not_to be_empty
      if ["5.5.0","5.5.1"].include? meta["AppVersion"]
        expect(meta["Hou"]).not_to be_empty
        expect(meta["Minu"]).not_to be_empty
        expect(meta["Sec"]).not_to be_empty
      else
        expect(meta["Hour"]).not_to be_empty
        expect(meta["Minute"]).not_to be_empty
        expect(meta["Second"]).not_to be_empty
      end
    end
    
    context "with filepath" do
      it "looks at meta hash an" do
        @file_paths.each do |path|
          wahoo = WahooFitness.new(path)
          test_meta_helper(wahoo.meta)
        end
      end 
    end
    
    context "with string" do
      it "takes date data from meta and creates a date object" do
        @file_strings.map do |k,v|
          wahoo = WahooFitness.new(v,false)
          test_meta_helper(wahoo.meta)
        end
      end 
    end 
  end
  
  describe "heartrate" do
    def test_heartrate_helper(wahoo)
      hr = wahoo.interval_samples.map { |s| s.hr_heartrate.to_i }
      ahr = hr.inject(0){|running_total, item| running_total + item } /  hr.size
      expect(hr).to be_an_instance_of Array
      expect(hr.min).to be_an_instance_of Fixnum
      expect(hr.max).to be_an_instance_of Fixnum
      expect(ahr).to be_an_instance_of Fixnum 
    end
    
    context "with filepath" do
      it "takes workout samples and calculates min, max, and average hr" do
        @file_paths.each do |path|
          wahoo = WahooFitness.new(path)
          test_heartrate_helper(wahoo)
        end
      end
    end
    
    context "with string" do
      it "takes workout samples and calculates min, max, and average hr" do
        @file_strings.map do |k,v|
          wahoo = WahooFitness.new(v,false)
          test_heartrate_helper(wahoo)
        end
      end
    end
  end
  
  describe "Time" do
    def test_time_helper(wahoo)
      runningtime = wahoo.workout.runningtime.to_i
    end
    
    context "with filepath" do
      it "takes workout samples and calculates min, max, and average hr" do
        @file_paths.each do |path|
          wahoo = WahooFitness.new(path)
          test_time_helper(wahoo)
        end
      end
    end
    
    context "with string" do
      it "takes workout samples and calculates min, max, and average hr" do
        @file_strings.map do |k,v|
          wahoo = WahooFitness.new(v,false)
          test_time_helper(wahoo)
        end
      end
    end
  end
  
  describe "Distance" do
    def test_distance_helper(wahoo)
      gpsdist = wahoo.workout.gpsdist.to_f
      stridedist = wahoo.workout.stridedist.to_f
      manual_dist = wahoo.workout.manual_dist.to_f
    end
    
    context "with filepath" do
      it "takes workout samples and calculates min, max, and average hr" do
        @file_paths.each do |path|
          wahoo = WahooFitness.new(path)
          test_distance_helper(wahoo)
        end
      end
    end
    
    context "with string" do
      it "takes workout samples and calculates min, max, and average hr" do
        @file_strings.map do |k,v|
          wahoo = WahooFitness.new(v,false)
          test_distance_helper(wahoo)
        end
      end
    end
  end
      
end