# frozen_string_literal: true

require 'erb'

# https://minecraft.fandom.com/ja/wiki/NBT%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%83%E3%83%88
module NBT
  class TypeError < StandardError; end
  class NBTRangeError < StandardError; end

  # _obj_ をMinecraftのNBT形式に変換し、NBTテキストをStringで返す
  def self.build(obj)
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
      NBTString.new(obj)
    in Array
      NBTList.new(obj)
    in Hash
      # _typeキーがあるmapは、valueをRubyコードとして処理し、結果を_typeの型にキャストする
      if obj['_type']
        code = obj.fetch('value')
        NBTProc.new(code, type: obj['_type'])
      else
        NBTCompound.new(obj)
      end
    end
  rescue NoMatchingPatternError => e
    raise NBT::TypeError
  end

  class NBTProc
    def initialize(code, type:, fname: code.lines.first.slice(0, 20), lineno: 1)
      @code = code.to_s.freeze
      @type = type
      @fname = fname
      @lineno = lineno
    end

    def eval_snbt(bind=nil)
      cast((bind || binding).eval(@code, @fname, @lineno)).eval_snbt
    end

    private

    def cast(obj)
      case @type
      when 'auto'
        NBT.build(obj)
      # ↓出力する必要が出てきたら足す
      when 'intarray'
        NBT::NBTIntArray.new(obj)
      end
    end
  end

  class NBTByteArray
    def initialize(obj)
      @obj = obj.map { NBTByte.new(_1) }.to_a.freeze
    end

    def eval_snbt(bind=nil)
      [
        '[B;',
        *@obj.map { |x| x.eval_snbt(bind) }.join(','),
        ']'
      ].join
    end
  end

  class NBTIntArray
    def initialize(obj)
      @obj = obj.map { NBTInteger.new(_1) }.to_a.freeze
    end

    def eval_snbt(bind=nil)
      [
        '[I;',
        *@obj.map { |x| x.eval_snbt(bind) }.join(','),
        ']'
      ].join
    end
  end

  class NBTLongArray
    def initialize(obj)
      @obj = obj.map { NBTLong.new(_1) }.to_a.freeze
    end

    def eval_snbt(bind=nil)
      [
        '[L;',
        *@obj.map { |x| x.eval_snbt(bind) }.join(','),
        ']'
      ].join
    end
  end

  class NBTCompound
    def initialize(obj)
      @obj = obj.transform_values { NBT.build(_1) }.freeze
    end

    def eval_snbt(bind=nil)
      [
        '{',
        *@obj.map do |k, v|
          if %r<\A[\d\w\-\.\+]\z>.match(k.to_s)
            kk = k.to_s
          else
            kk = NBTString.new(k).eval_snbt
          end
          vv = v.eval_snbt(bind)
          "#{kk}:#{vv}"
        end.join(','),
        '}'
      ].join
    end
  end

  class NBTList
    def initialize(obj)
      @obj = obj.map { NBT.build(_1) }.to_a.freeze
    end

    def eval_snbt(bind=nil)
      [
        '[',
        *@obj.map { |x| x.eval_snbt(bind) }.join(','),
        ']'
      ].join
    end
  end

  class NBTString
    def initialize(obj) = @obj = obj.to_s.freeze

    def eval_snbt(bind=nil)
      if bind
        v = ERB.new(@obj).result(bind)
      else
        v = @obj
      end
      ['"', v.gsub('"', '\"'), '"'].join
    end
  end

  class NBTByte
    RANGE = -0x80..0x7f
    def initialize(obj)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def eval_snbt(_bind=nil) = "#{@obj}B"
  end

  class NBTShort
    RANGE = -0x8000..0x7fff
    def initialize(obj)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def eval_snbt(_bind=nil) = "#{@obj}S"
  end

  class NBTInteger
    RANGE = -0x80000000..0x7fffffff
    def initialize(obj)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def eval_snbt(_bind=nil) = "#{@obj}"
  end

  class NBTLong
    RANGE = -0x8000000000000000..0x7fffffffffffffff
    def initialize(obj)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_i
    end

    def eval_snbt(_bind=nil) = "#{@obj}L"
  end

  class NBTFloat
    RANGE = -1.7E+308..1.7E+308
    def initialize(obj)
      raise NBTRangeError unless RANGE.include?(obj)
      @obj = obj.to_f
    end

    def eval_snbt(_bind=nil) = "#{@obj}F"
  end
end
