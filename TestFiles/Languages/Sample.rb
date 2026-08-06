# Sample.rb — exercises Moped's Ruby tokenizer.
class Playlist
  attr_reader :name, :tracks

  def initialize(name)
    @name = name
    @tracks = []
  end

  def add_track(title, duration_seconds)
    @tracks << { title: title, duration: duration_seconds }
  end

  def total_duration
    @tracks.sum { |t| t[:duration] }
  end
end

playlist = Playlist.new("Focus Mix")
playlist.add_track("Morning Light", 210)
playlist.add_track("Deep Work", 305)

puts "Playlist: #{playlist.name}"
playlist.tracks.each do |track|
  puts "  - #{track[:title]} (#{track[:duration]}s)"
end

puts "Total duration: #{playlist.total_duration}s"

=begin
A block comment, which Ruby anchors to the start of the line.
=end
# Literal forms that trip tokenizers.
quoted = "she said \"hello\" and left"
single = 'it\'s escaped'
words = %w[alpha beta gamma]
heredoc = <<~REPORT
  spans lines, keeps "quotes" verbatim
REPORT
bases = [0xFF, 0b1010_1010, 0o755, 1_000_000]
puts [quoted, single, words.length, heredoc.strip, bases.sum].inspect
