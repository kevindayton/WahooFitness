##
# Copyright (c) 2015 Kevin L. Dayton
# Copyright (c) 2015 Volatile Eight Industries
# Copyright (c) 2015 Dayton Interactive
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'csv'
require 'active_support/inflector'

##
# WahooFitness
#
# This class represents the overall workout as recorded by the Wahoo Fitness app.
# Based on the files produced by Wahoo Fitness iOS app Version 5.5.1
# https://itunes.apple.com/us/app/wahoo-fitness-bluetooth-powered/id391599899?mt=8
class WahooFitness
  
  attr_accessor :meta
  attr_accessor :comments
  attr_accessor :sensors
  attr_accessor :workout
  attr_accessor :intervals
  attr_accessor :interval_samples
  
  ## 
  # Public: Initialize a new instance of WahooFitness
  #
  # path  - The file path of the file to be parsed.
  #
  # Examples
  #
  #   initialize("2015-03-22-1403_Bikingdata.csv")
  #   # => true
  #
  # Returns the new instance with parsed data.
  def initialize(path)
    @data = CSV.read(path)
    parse
  end
  
  protected
  
  ## 
  # Protected: Runs through all the parser method
  #
  # Returns nothing
  def parse
    @meta = parse_meta
    @comments = parse_comments
    @sensors = parse_sensors
    @workout = parse_workout
    @intervals = parse_intervals
    @interval_samples = parse_interval_samples
  end
  
  ## 
  # Protected: Parse workout meta data
  #
  # Returns a hash of meta data
  def parse_meta
    meta = Hash.new
    meta[@data[0][0]] = @data[0][1]
    meta[@data[0][2]] = @data[0][3]
    meta[@data[0][4]] = @data[0][5]
    meta[@data[0][6]] = @data[0][7]
    meta[@data[1][0]] = @data[1][1]
    meta[@data[1][2]] = @data[1][3]
    meta[@data[1][4]] = @data[1][5]
    meta[@data[1][6]] = @data[1][7]
    meta[@data[1][8]] = @data[1][9]
    meta[@data[1][10]] = @data[1][11]
    meta[@data[1][12]] = @data[1][13]
    # This is some cleanup that needs to happen because of an oddity (bug?) in 
    # the WF/CSV files in version 5.5.1.
    day = Hash.new
    hour = Hash.new
    minu = Hash.new
    sec = Hash.new
    meta.each do |k,v|
      if !k.nil?
        if k.include? "Day"
          d = k.split(/([0-9]+)/) 
          day[d[0]] = d[1]
          h = v.split(/([0-9]+)/) 
          hour[h[0]] = h[1]
          meta.delete(k)
        elsif k.include? "Minu"
          m = k.split(/([0-9]+)/) 
          minu[m[0]] = m[1]
          s = v.split(/([0-9]+)/) 
          sec[s[0]] = s[1]
          meta.delete(k)
        end
      else
        meta.delete(k)
      end
    end 
    meta.merge! day
    meta.merge! hour
    return meta
  end

  ##
  # Protected: Parse workout comments
  #
  # Returns a string of comments
  def parse_comments
    @data[4][0]
  end

  ##
  # Protected: Parses sensors
  #
  # Returns an array of sensors
  def parse_sensors
    sensors = Array.new
    @data[7..12].map.with_index do |s,i|
      index = 7 + i
      zipped = @data[6].zip(@data[index])
      sensors[i] = WFSensor.new
      s.map.with_index do |e,n|
        case n
          when 0
            sensors[i].type = e
          when 1
            sensors[i].present = e 
         when 2
            sensors[i].smrec = e
          when 3
            sensors[i].zeroavg = e
          when 4
            sensors[i].model = e 
          end
      end
    end
    return sensors
  end
  
  ##
  # Protected: Parses workout overview
  #
  # Returns a WFWorkout
  def parse_workout
    @data[13].map!(&:underscore)
    zipped = (@data[13]).zip(@data[14])
    w = WFWorkout.new
    Hash[zipped].map { |k,v|
      w.instance_variable_set("@#{k}",v)
    }
    workout = w
  end
  
  ##
  # Protected: Parses workout intervals
  #
  # Returns an array of WFWorkoutInterval
  def parse_intervals
    intervals = Array.new
    headers_index = 16
    data_index = headers_index + 1
    headers = @data[headers_index].map!(&:underscore)
    current_interval = nil
    @data[data_index,@data.size].map.with_index do |r,i|
      if r.empty?
        @_interval_sample_index = data_index + i + 1
        break
      else
        zipped = (headers).zip(@data[data_index + i])
        i = WFWorkoutInterval.new
        Hash[zipped].map { |k,v|
          if k == "interval"
            if current_interval == v
              i.subinterval = true
            else
              i.subinterval = false
            end
            current_interval = v
          end
          i.instance_variable_set("@#{k}",v)
        }
        intervals.push(i)
      end
    end
    return intervals
  end
  
  ##
  # Protected: Parses workout interval samples
  #
  # Returns an array of WFCSVWorkoutIntervalSample
  def parse_interval_samples
    interval_samples = Array.new
    headers_index = @_interval_sample_index
    headers = @data[headers_index].map!(&:underscore)
    data_index = headers_index + 1
    @data[data_index,@data.size].map.with_index do |r,i|
      if r.empty?
        break
      else
        zipped = headers.zip(@data[data_index + i])
        s = WFCSVWorkoutIntervalSample.new
        Hash[zipped].map { |k,v|
          s.instance_variable_set("@#{k}",v)
        }
      end
      interval_samples.push(s)
    end
    return interval_samples
  end       
end

##
# WFSensor
#
# This class represents a device used during a given workout. 
class WFSensor
  attr_accessor :type
  attr_accessor :present
  attr_accessor :smrec
  attr_accessor :zeroavg
  attr_accessor :model
end

##
# WFWorkout
#
# This class represents the summary of a given workout. 
class WFWorkout
  attr_accessor :workout
  attr_accessor :starttime
  attr_accessor :runningtime
  attr_accessor :pausedtime
  attr_accessor :wheeldist
  attr_accessor :cadavg
  attr_accessor :spdavg
  attr_accessor :pwravg
  attr_accessor :pwr_pedal_contribution
  attr_accessor :hravg
  attr_accessor :striderateavg
  attr_accessor :stridedist
  attr_accessor :gpsdist
  attr_accessor :smoothnessavg
  attr_accessor :manualdist
end

##
# WFWorkoutInterval
#
# This class represents the summary of a given workout.
#
# TODO: Add samples as an attribute.
class WFWorkoutInterval < WFWorkout
  attr_accessor :subinterval
  
  def initialize
    @subinterval = false
  end
end

##
# WFCSVWorkoutIntervalSample
#
# This class represents a given sample as parsed from the CSV file.
class WFCSVWorkoutIntervalSample
  attr_accessor :cad_cadence
  attr_accessor :disp_altitude
  attr_accessor :disp_atmospressure
  attr_accessor :disp_temperature
  attr_accessor :fp_accdist
  attr_accessor :fp_accsteps
  attr_accessor :fp_speed
  attr_accessor :gps_altitude
  attr_accessor :gps_dist
  attr_accessor :gps_lat
  attr_accessor :gps_lon
  attr_accessor :gps_speed
  attr_accessor :hr_heartrate
  attr_accessor :interval
  attr_accessor :ma_cadence
  attr_accessor :ma_gct
  attr_accessor :ma_jerkx
  attr_accessor :ma_jerky
  attr_accessor :ma_jerkz
  attr_accessor :ma_riderposition
  attr_accessor :ma_smoothness
  attr_accessor :ma_smoothness_x
  attr_accessor :ma_smoothness_y
  attr_accessor :ma_smoothness_z
  attr_accessor :ma_trunkangle
  attr_accessor :ma_vertosc
  attr_accessor :manual_dist
  attr_accessor :manual_speed
  attr_accessor :paused
  attr_accessor :pwr_accdist
  attr_accessor :pwr_cadence
  attr_accessor :pwr_instpwr
  attr_accessor :pwr_left_pedal
  attr_accessor :pwr_right_pedal
  attr_accessor :pwr_speed
  attr_accessor :pwr_torque
  attr_accessor :spd_accdist
  attr_accessor :spd_instspeed
  attr_accessor :time
end