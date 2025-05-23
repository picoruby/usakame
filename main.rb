#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'listen'
  gem 'logger'
end

class Rapicco
  class Sprite
    def initialize(rows, palette)
      @pos = 0
      @data = rows.map do |row|
        out = ""
        i = 0
        prev = nil
        adjust = 0
        while i < row.length
          ch = row[i]
          case ch
          when ';'
            adjust = -1
            out << "\e[2K"
            i += 1
          when '.'
            j = i
            j += 1 while j < row.length && row[j] == '.'
            n = j - i
            out << "\e[0m" if prev
            prev = nil
            out << (n == 1 ? "\e[C" : "\e[#{n}C")
            i = j
          else
            color = palette[ch]
            if color != prev
              out << "\e[48;5;#{color}m"
              prev = color
            end
            out << ' '
            i += 1
          end
        end
        out << "\e[0m" if prev
        out << "\e[#{row.length + adjust}D\e[B" # Carriage return
        out
      end
      @width = rows.map(&:length).max
      @height = @data.size
    end

    attr_accessor :pos
    attr_reader :width, :height

    def show
      @data.each { |l| print l }
    end
  end
end

def refresh
  load './data.rb'
  print "\e[H\e[2J\e[B"
  (0..255).each do |i|
    print "\e[38;5;#{i}mcolor%-5i\e[0m" % i
    puts if (i + 1) % 8 == 0
  end
  puts
  rapiko = Rapicco::Sprite.new($rapiko, $palette)
  camerlengo = Rapicco::Sprite.new($camerlengo, $palette)
  bullet = Rapicco::Sprite.new($bullet, $palette)
  rapiko.show
  print "\e[#{rapiko.height}A\e[#{rapiko.width+4}C"
  camerlengo.show
  print "\e[#{camerlengo.height}A\e[#{camerlengo.width+4}C"
  bullet.show
  print "\e[#{bullet.height}A"
  print "\e[#{rapiko.height}B\e[E"
  print "         Copyright (c) #{$author}. MIT License"
end

begin
  print "\e[?1049h" # DECSET 1049
  print "\e[?25l" # hide cursor
  listener = Listen.to('./') do |modified, added, removed|
    refresh
  end
  refresh
  listener.start
  sleep
ensure
  print "\e[?1049l" # DECRST 1049
  print "\e[?25h" # show cursor
end
