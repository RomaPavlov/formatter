require 'mysql2'

class Formatter

  WRONG_VALUES = ['N/A' 'unknown' 'none given']

  def initialize(host: 'localhost', username: '', password: '', database: '')
    @client = Mysql2::Client.new(host: host, username: username, password: password, database: database)
  end

  def format
    select.each do |row|
      @str = row["candidate_office_name"]
      clean_name = format_string
      sentence = "The candidate is running for the #{clean_name} office."
      insert(row['id'], clean_name, sentence)
    end
  end

  private

    def select
      @client.query("SELECT * FROM hle_dev_test_roman_kislitsin;")
    end

    def format_string
      ['twp', 'hwy'].any? { |word| decode_abbreviations if @str.downcase.include?(word) }
      delete_slashes
      capitalize_parentheses if @str.include?('(')
      delete_duplicates
    end

    def capitalize_parentheses
      ary = @str.split('(')
      capitalized = ary[1].split(' ').map(&:capitalize).join(' ')
      @str = ary.shift(1).push(capitalized).join('(')
    end

    def decode_abbreviations
      {'Twp' => ' Township ', 'Hwy' => ' Highway '}.each {|k, v| @str.gsub!(k, v)}
    end

    def delete_slashes
      return if WRONG_VALUES.any? { |word| @str.include?(word) } || @str.length.zero?
      strings_array = @str.split(/\//).reject { |e| e.to_s.empty? }
      # Delete dots if they are in the end of phrase
      strings_array.each {|str| delete_periods(str) if str.include? '.'}
      substrings = to_parentheses(strings_array)
      if substrings.length > 1
        @str = ''
        substrings = substrings.unshift(substrings.pop)
        substrings.each_with_index do |el, i|
          @str += case i
                  when 0
                    el
                  when 1
                    " #{el.downcase}"
                  else
                    " and #{el.downcase}"
                  end
        end
      else
        @str = substrings[0].include?('(') ? substrings[0] : substrings[0].downcase
      end
    end

    def delete_duplicates
      @str = @str.split.uniq(&:capitalize).join(' ')
    end

    def delete_periods(str)
      str.gsub!('.', '') if str[-1] == '.'
    end

    def to_parentheses(strings_array)
      strings_array.map do |string|
        string.include?(',') ? string_with_parentheses(string) : string
      end
    end

    def string_with_parentheses(string)
      str = string.split(',')
      # if comma is the last symbol of substring
      return "#{str[0].downcase}" if str.length == 1
      "#{str[0].downcase} (#{str[1].split.map(&:capitalize).join(' ') if str[1]})"
    end

    def insert(id, clean_name, sentence)
      @client.query("UPDATE hle_dev_test_roman_kislitsin SET clean_name = \"#{clean_name}\", sentence = \"#{sentence}\" WHERE id = \"#{id}\";")
    end
end

formatter = Formatter.new(host: '', username: '', password: '', database: '')
formatter.format