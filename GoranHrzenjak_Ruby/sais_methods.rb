#!/usr/bin/env ruby



class SAIS
  
  def initialize(input_string)
    @original_input_string = input_string
  end
  
  
  def calculate_suffix_array
    puts "\n............................"
    puts "........CALCULATING........."
    puts "............................\n"
    
    @output_suffix_array = main_sais(@original_input_string)
    
    puts "\n............................"
    puts "...........OVER............."
    puts "............................\n\n"
  end
  
  def get_output_SA
    return @output_suffix_array
  end
  
  
  def main_sais(input_string)
    
    puts "\n\n ---- MAIN SAIS CALL ----\n"
    puts "#{input_string.size} chars"
    print_time("Start!")
    
  
    
    t_array = classify_type_of_chars(input_string)
    #print "T: "
    #puts t_array.to_s
    

    
    
    bucket_pointers = determine_buckets(input_string, true)
    #print "B: "
    #puts bucket_pointers.to_s
    
    print_time("After determining buckets")

    # new suffix array
    suffix_array = initialize_suffix_array(input_string.size)
    
    
    # p_1 array
    lms_pointers = determine_LMS_substring_pointers(t_array, bucket_pointers,
                                                  suffix_array, input_string)
    #print "P1: "
    #puts lms_pointers.to_s
    #print "SA after 1st step: "
    #puts suffix_array.to_s
    
    
    induce_SA_L(t_array, bucket_pointers, suffix_array, input_string)
    #print "SA (after induceSA_L): "
    #puts suffix_array.to_s
    
    print_time("After Induce SA_L")
    
    
    induce_SA_S(t_array, bucket_pointers, suffix_array, input_string)
    #print "SA (after induceSA_S): "
    #puts suffix_array.to_s
    
    print_time("After Induce SA_S")
    
    
    unique_chars, shortened_string_s1 =
      name_LMS_substring_t2(lms_pointers, suffix_array, t_array, input_string)
    
    print_time("After naming")
    
    #print "S1: "
    #puts shortened_string_s1.to_s
    
    if (unique_chars)
      #puts "directly computing SA1 from SA1"
      suffix_array_short = directly_compute_shortened_SA(shortened_string_s1)
    else
      #puts "recursion"
      suffix_array_short = main_sais(shortened_string_s1)
      #puts "returned from recursion"
    end
    
    #print "SA1: "
    #puts suffix_array_short.to_s
    
    #induce SA from SA1
    #puts "inducing sa from sa1..."

    induce_final_suffix_array(t_array, bucket_pointers, suffix_array, input_string,
                          suffix_array_short, lms_pointers)
    
    print_time("After final inducing!")
    
    return suffix_array
  
  end
  
  
  def initialize_suffix_array(size)
    sa = Array.new(size, -1)
    return sa
  end
  
  
  # "private" methods called from main sais function
  def initialize_suffix_array(size)
    sa = Array.new(size, -1)
    return sa
  end
  
  
  def classify_type_of_chars(input_string)
    # array of L- or S-type characters
    # S-type : value 1, L-type : value 0
    t_array = Array.new
    
    str_reversed = input_string.reverse
    str_reversed.each_with_index do |ascii_val, index|
      
      if index == 0
        # the last suffix (char) is always S-type
        t_array << 1
      elsif index == 1
        t_array << 0 
      else
        t_array << ((ascii_val < str_reversed[index - 1] ||
              ascii_val == str_reversed[index - 1] && t_array[index - 1] == 1) ? 1 : 0)
    
      end

    end
    t_array.reverse!
    return t_array
  end

  
  def determine_buckets(input_string_array, set_to_end, *old_buckets)
    
    chars_count = Hash.new(0)
    # calculate number of occurrences of each character in input 
    input_string_array.each do |v|
      chars_count[v] +=1
    end
    
    if old_buckets.size > 0
      bucket_pointers = set_buckets_pointers(chars_count, set_to_end, old_buckets)
    else
      bucket_pointers = set_buckets_pointers(chars_count, set_to_end)
    end
    
    return bucket_pointers
    
  end
  
  
  def set_buckets_pointers(chars_count, set_to_end, *old_buckets)
    
    # set bucket pointers
    # if set_to_end is True, pointer will be on last element
    # if new_buckets is True, create new Hash, othervise just clear
    if old_buckets.size == 0
      bucket_pointers = Hash.new(0)
    else
      bucket_pointers = old_buckets[0][0]
      bucket_pointers.clear

    end

    total_count = 0
    
    chars_count.sort.map do |char, count|
      total_count += count
      bucket_pointers[char] =
        (set_to_end ? (total_count - 1) : (total_count - count))

    end
    
    #puts bucket_pointers.to_s
    
    return bucket_pointers
  end
  
  
  def determine_LMS_substring_pointers(t_array, bucket_pointers,
                                       suffix_array, input_string)
    p_1 = []
    t_array.each_with_index do |type, index|
      if type == 1 && index > 0 && t_array[index - 1] == 0
        p_1 << index
        
        # add LMS suffix index to SA in appropriate bucket
        # shift bucket pointer left
        # (1st step of induced sort algorithm I)
        char_value = input_string[index]
        pointer = bucket_pointers[char_value]
        bucket_pointers[char_value] -= 1
        suffix_array[pointer] = index
      end
      
    end
    return p_1
  end
  
  
  def induce_SA_L(t_array, bucket_pointers,
                  suffix_array, input_string)
    # (2nd step of induced sort algorithm )
    # set bucket pointers to the FIRST element of each bucket
    #bucket_pointers = determine_buckets(input_string, false, bucket_pointers)

    bucket_pointers = determine_buckets(input_string, false, bucket_pointers)

    
    # foreach SA[i] > 0 check type
    suffix_array.each_with_index do |val, index|
      new_value = suffix_array[index]
      
      if new_value > 0
        if (t_array[new_value - 1] == 0)
          # if the type is L, add SA[i]-1 to the BEGGINING of appropriate bucket
          # shift bucket pointer RIGHT
          char_value = input_string[new_value - 1]
          pointer = bucket_pointers[char_value]
          bucket_pointers[char_value] += 1
          suffix_array[pointer] = new_value - 1
          
          #puts suffix_array.to_s
        end
      end

    end
  end
  
  
  def induce_SA_S(t_array, bucket_pointers,
                  suffix_array, input_string)
    # (3rd step of induced sort algorithm)
    # set bucket pointers to the LAST element of each bucket
    bucket_pointers = determine_buckets(input_string, true, bucket_pointers)


    # foreach SA[i] > 0 check type
    # this time, check SA from the end to the beggining
    suffix_array.reverse.each_with_index do |val, index|

      new_value = suffix_array[-(index + 1)]
      if new_value > 0
        
        if (t_array[new_value - 1] == 1)

          # if the type is S, add SA[i]-1 on the END of appropriate bucket
          # shift bucket pointer LEFT
          char_value = input_string[new_value - 1]
          pointer = bucket_pointers[char_value]
          bucket_pointers[char_value] -= 1
          suffix_array[pointer] = new_value - 1
          
          #puts suffix_array.to_s
        end
      end
    end  
    #puts bucket_pointers.to_s
  end
  
  
  
  
  def name_LMS_substring(lms_pointers, suffix_array, t_array, input_string)
    
    # True only if each character in S_1 is unique
    each_char_unique = true
    
    # S_1
    shortened_string = Array.new(lms_pointers.size, -1)
    
    names_count = 0
    previous_substring_index = -1
    

    puts "count of lms = #{lms_pointers.size}"

    print ".."
    lms_pointers_hash = Hash[lms_pointers.map.with_index.to_a]
    print ".."
    
    n = suffix_array.size
    
    substring_index = lms_pointers.index(suffix_array[0])
      unless substring_index.nil?
        shortened_string[substring_index] = names_count
        previous_substring_index = substring_index
      end
    
    for idx in (2..(n-1))
      value = suffix_array[idx]
      ###substring_index = lms_pointers.index(value)
      substring_index = lms_pointers_hash[value]
      unless substring_index.nil?

        # Are LMS substrings equal?
        
        ##
        if substring_index == lms_pointers.size - 1
          current_substring = input_string[value]
          current_substring_type = t_array[value]
        else
          current_substring = input_string[value..lms_pointers[substring_index + 1]]
          current_substring_type = t_array[value..lms_pointers[substring_index + 1]]
        end
        
        if previous_substring_index == lms_pointers.size - 1
          previous_substring = input_string[lms_pointers[previous_substring_index]]
          previous_substring_type = t_array[lms_pointers[previous_substring_index]]
        else
          previous_substring = input_string[lms_pointers[previous_substring_index]..
                                            lms_pointers[previous_substring_index + 1]]
          previous_substring_type = t_array[lms_pointers[previous_substring_index]..
                                            lms_pointers[previous_substring_index + 1]]
        end
        
        
        # Check lenght, compare all characters and
        # type of every character
        if (current_substring.size == previous_substring.size &&
            current_substring.eql?(previous_substring) &&
           current_substring_type.eql?(previous_substring_type))
          each_char_unique = false
        else
          # NOT equal LMS substrings
          names_count += 1
        end
        
        shortened_string[substring_index] = names_count
        previous_substring_index = substring_index

      end
    end
    


    return each_char_unique, shortened_string
  end
  
  
  def directly_compute_shortened_SA(shortened_string)
    suffix_array_short = Array.new(shortened_string.size, -1)
    shortened_string.each_with_index do |value, index|
      suffix_array_short[value] = index
    end
    return suffix_array_short
  end
  
  
  
  def induce_final_suffix_array(t_array, bucket_pointers, suffix_array,
                   input_string, suffix_array_short, lms_pointers)
    #puts "Induce SA from SA1"
    suffix_array.map! {|x| x = -1}

    bucket_pointers = determine_buckets(input_string, true, bucket_pointers)

    suffix_array_short.to_enum.with_index.reverse_each do |value, index|
      char_position = lms_pointers[suffix_array_short[index]]

      pointer = bucket_pointers[input_string[char_position]]
      bucket_pointers[input_string[char_position]] -= 1
      suffix_array[pointer] = char_position
 
    end
    
    induce_SA_L(t_array, bucket_pointers, suffix_array, input_string)

    induce_SA_S(t_array, bucket_pointers, suffix_array, input_string)

    
  end
  
end