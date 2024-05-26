# frozen_string_literal: true

require 'erb'

# https://minecraft.fandom.com/ja/wiki/NBT%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%83%E3%83%88
module NBT
  class TypeError < StandardError; end
  class NBTRangeError < StandardError; end

  # _obj_ をMinecraftのNBT形式に変換し、NBTテキストをStringで返す
  def self.build(obj, bind: nil)
    case obj
    in true
      NBTByte.new(1)
    in false
      NBTByte.new(0)
    in Integer => a if NBTByte::RANGE.include?(a)
      NBTByte.new(obj)
    in Integer => a if NBTShort::RANGE.include?(a)
      NBTShort.new(obj)
    in Integer => a if NBTInteger::RANGE.include?(a)
      NBTInteger.new(obj)
    in Integer => a if NBTLong::RANGE.include?(a)
      NBTLong.new(obj)
    in Float | Rational => a if NBTFloat::RANGE.include?(a)
      NBTFloat.new(obj)         # Floatとdoubleは区別しないことにした
    in 'MINECRAFT_UUID'         # ランダムなUUIDを作る
      NBTIntArray.new(SecureRandom.random_bytes(16).unpack("i4"))
    in String | Symbol
      NBTString.new(obj, bind:)
    in Array
      NBTList.new(obj, bind:)
    in Hash
      # _typeキーがあるmapは、valueをRubyコードとして処理し、結果を_typeの型にキャストする
      if obj['_type']
        code = obj.fetch('value')
        NBTProc.new(code, bind:, type: obj['_type']).nbt
      else
        NBTCompound.new(obj, bind:)
      end
    end
  rescue NoMatchingPatternError => e
    raise NBT::TypeError
  end

  class NBTProc
    attr_reader :nbt

    def initialize(code, bind: nil, type:, fname: code.lines.first.slice(0, 20), lineno: 1)
      @code = code.to_s.freeze
      @type = type
      @fname = fname
      @lineno = lineno
      @nbt = cast((bind || binding).eval(@code, @fname, @lineno))
    end

    private

    def cast(obj)
      case @type
      when 'auto'
        NBT.build(obj)
      # ↓出力する必要が出てきたら足す
      when 'byte'
        NBT::NBTByte.new(obj)
      when 'intarray'
        NBT::NBTIntArray.new(obj)
      end
    end
  end

  class NBTByteArray
    def initialize(obj, bind: nil)
      @obj = obj.map { NBTByte.new(_1, bind:) }.to_a.freeze
    end

    def snbt
      [
        '[B;',
        *@obj.map(&:snbt).join(','),
        ']'
      ].join
    end
  end

  class NBTIntArray
    def initialize(obj, bind: nil)
      @obj = obj.map { NBTInteger.new(_1, bind:) }.to_a.freeze
    end

    def snbt
      [
        '[I;',
        *@obj.map(&:snbt).join(','),
        ']'
      ].join
    end
  end

  class NBTLongArray
    def initialize(obj, bind: nil)
      @obj = obj.map { NBTLong.new(_1, bind:) }.to_a.freeze
    end

    def snbt
      [
        '[L;',
        *@obj.map(&:snbt).join(','),
        ']'
      ].join
    end
  end

  class NBTCompound
    def initialize(obj, bind: nil)
      @obj = obj.transform_values { NBT.build(_1, bind:) }.freeze
    end

    def snbt
      [
        '{',
        *@obj.map do |k, v|
          if %r<\A[\d\w\-\.\+]\z>.match(k.to_s)
            kk = k.to_s
          else
            kk = NBTString.new(k).snbt
          end
          vv = v.snbt
          "#{kk}:#{vv}"
        end.join(','),
        '}'
      ].join
    end
  end

  class NBTList
    def initialize(obj, bind: nil)
      @obj = obj.map { NBT.build(_1, bind:) }.to_a.freeze
    end

    def snbt
      [
        '[',
        *@obj.map(&:snbt).join(','),
        ']'
      ].join
    end
  end

  class NBTString
    def initialize(obj, bind: nil)
      if bind
        @obj = ERB.new(obj).result(bind).freeze
      else
        @obj = obj.to_s.freeze
      end
    end

    def snbt
      ['"', @obj.gsub('"', '\"'), '"'].join
    end
  end

  class NBTByte
    RANGE = -0x80..0x7f
    def initialize(obj, bind: nil)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def snbt = "#{@obj}B"
  end

  class NBTShort
    RANGE = -0x8000..0x7fff
    def initialize(obj, bind: nil)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def snbt = "#{@obj}S"
  end

  class NBTInteger
    RANGE = -0x80000000..0x7fffffff
    def initialize(obj, bind: nil)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def snbt = "#{@obj}"
  end

  class NBTLong
    RANGE = -0x8000000000000000..0x7fffffffffffffff
    def initialize(obj, bind: nil)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def snbt = "#{@obj}L"
  end

  class NBTFloat
    RANGE = -1.7E+308..1.7E+308
    def initialize(obj, bind: nil)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_f
    end

    def snbt = "#{@obj}F"
  end
end
