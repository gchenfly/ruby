class Reline::KeyStroke
  using Module.new {
    refine Array do
      def start_with?(other)
        other.size <= size && other == self.take(other.size)
      end

      def bytes
        self
      end
    end
  }

  def initialize(config)
    @config = config
    @buffer = []
  end

  def input_to(bytes)
    case match_status(bytes)
    when :matching
      nil
    when :matched
      expand(bytes)
    when :unmatched
      bytes
    end
  end

  def input_to!(bytes)
    if bytes.nil?
      return @buffer.push(nil)&.tap { clear }
    end
    @buffer.concat Array(bytes)
    input_to(@buffer)&.tap { clear }
  end

  private

  def match_status(input)
    key_mapping.keys.select { |lhs|
      lhs.start_with? input
    }.tap { |it|
      return :matched  if it.size == 1 && (it.max_by(&:size)&.size&.== input.size)
      return :matching if it.size == 1 && (it.max_by(&:size)&.size&.!= input.size)
      return :matched  if it.max_by(&:size)&.size&.< input.size
      return :matching if it.size > 1
    }
    key_mapping.keys.select { |lhs|
      input.start_with? lhs
    }.tap { |it|
      return it.size > 0 ? :matched : :unmatched
    }
  end

  def expand(input)
    lhs = key_mapping.keys.select { |lhs| input.start_with? lhs }.sort_by(&:size).reverse.first
    return input unless lhs
    rhs = key_mapping[lhs]

    case rhs
    when String
      rhs_bytes = rhs.bytes
      expand(expand(rhs_bytes) + expand(input.drop(lhs.size)))
    when Symbol
      [rhs] + expand(input.drop(lhs.size))
    end
  end

  def key_mapping
    @config[:key_mapping].transform_keys(&:bytes)
  end

  def clear
    @buffer = []
  end
end
