#--
# Copyright (c) 2015 Kevin L. Dayton
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
#++

require 'csv'
require 'active_support/inflector'

class WahooFitness
  
  attr_accessor :meta
  attr_accessor :comments
  attr_accessor :sensors
  attr_accessor :workout
  
  # Public: Initialize a new instance of WahooFitness
  #
  # path  - The file path of the file to be parsed.
  #
  # Examples
  #
  #   initialize("2015-03-22-1403_Biking_WF.wf")
  #   # => true
  #
  # Returns the new instance.
  def initialize(path)
    @meta = Hash.new
    @sensors = Array.new
    @intervals = Array.new
    @data = CSV.read(path)
    self.parse
  end
  
  def parse
    parse_meta
    parse_comments
    parse_sensors
    parse_workout
    parse_intervals
  end
  
  private
  
  def parse_meta
    @meta[@data[0][0]] = @data[0][1]
    @meta[@data[0][2]] = @data[0][3]
    @meta[@data[0][4]] = @data[0][5]
    @meta[@data[0][6]] = @data[0][7]
    @meta[@data[1][0]] = @data[1][1]
    @meta[@data[1][2]] = @data[1][3]
    @meta[@data[1][4]] = @data[1][5]
    @meta[@data[1][6]] = @data[1][7]
    @meta[@data[1][8]] = @data[1][9]
    @meta[@data[1][10]] = @data[1][11]
    @meta[@data[1][12]] = @data[1][13]
  end

  def parse_comments
    @comments = @data[4]
  end

  def parse_sensors
    @data[7..12].map.with_index do |s,i|
      index = 7 + i
      zipped = @data[6].zip(@data[index])
      @sensors[i] = WFSensor.new
      s.map.with_index do |e,n|
        case n
          when 0
            @sensors[i].type = e
          when 1
            @sensors[i].present = e 
         when 2
            @sensors[i].smrec = e
          when 3
            @sensors[i].zeroavg = e
          when 4
            @sensors[i].model = e 
          end
      end
    end
  end
  
  def parse_workout
    @data[13].map!(&:underscore)
    zipped = (@data[13]).zip(@data[14])
    w = WFWorkout.new
    Hash[zipped].map { |k,v|
      w.instance_variable_set("@#{k}",v)
    }
    @workout = w
  end
  
  def parse_intervals
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
        @intervals.push(i)
      end
    end
  end   
end

class WFSensor
  attr_accessor :type
  attr_accessor :present
  attr_accessor :smrec
  attr_accessor :zeroavg
  attr_accessor :model
end

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

class WFWorkoutInterval < WFWorkout
  attr_accessor :subinterval
  
  def initialize
    @subinterval = false
  end
end