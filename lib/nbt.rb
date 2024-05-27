# frozen_string_literal: true

require 'erb'

# https://minecraft.fandom.com/ja/wiki/NBT%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%83%E3%83%88
module NBT
  class TypeError < StandardError; end
  class NBTRangeError < StandardError; end
  class KeyError < StandardError; end
  module NBTObjectType; end # NBT型の一種であることを示すmix-in

  # _obj_ をMinecraftのNBT形式に変換する。
  # @return [NBT] NBTオブジェクト
  def self.build(obj, bind: nil, allow_nil: false)
    case obj
    in NBTObjectType
      obj
    in true | false
      NBTBoolean.new(obj)
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
      type = obj['_type'] || obj[:_type]
      if type
        code = obj.fetch('value') { obj.fetch(:value) }
        NBTProc.new(code, bind:, type:).nbt
      else
        NBTCompound.new(obj, bind:)
      end
    in nil
      raise NBT::TypeError, "NBT.build に nil を渡した" unless allow_nil
    end
  rescue NoMatchingPatternError => e
    raise NBT::TypeError, "#{obj.class} の取り扱い方は不明"
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
    include NBTObjectType

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

    def to_json(...) = @obj.to_json(...)
    def hash = [@obj, self.class].hash
  end

  class NBTIntArray
    include NBTObjectType

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

    def to_json(...) = @obj.to_json(...)
    def hash = [@obj, self.class].hash
  end

  class NBTLongArray
    include NBTObjectType

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

    def to_json(...) = @obj.to_json(...)
    def hash = [@obj, self.class].hash
  end

  class NBTCompound
    include NBTObjectType

    def initialize(obj, bind: nil)
      @obj = obj.to_h { |k, v| [k.to_s, NBT.build(v, bind:)] }.freeze
    end

    def snbt
      [
        '{',
        *@obj.map do |k, v|
          if %r<\A[\d\w\-\.\+]+\z>.match(k.to_s)
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

    def to_json(...) = @obj.to_json(...)
    def to_h = @obj
    def hash = [@obj, self.class].hash

    def [](k)
      return nil unless k in String | Symbol
      key = k.to_s
      @obj[key]
    end

    def dig(*path)
      k, *rest = path.flatten
      return nil unless k in String | Symbol
      key = k.to_s
      if rest.empty?
        self[key]
      else
        self[key]&.dig(*rest)
      end
    end

    # pathの内容をvalueに変更したオブジェクトを返す。
    # selfは変化させない。
    def cow(path, value)
      k, *rest = path
      raise TypeError, "#{self.class}#cow: キーは String|Symbol (実際に渡したのは #{k.class})" unless k in String | Symbol
      key = k.to_s
      if rest.empty?
        NBTCompound.new(@obj.merge({ key.to_s => value }))
      else
        child = @obj[key.to_s]
        if child
          NBTCompound.new(@obj.merge({ key.to_s => child.cow(rest, value) }))
        else
          raise KeyError, "#{self.class}#cow: #{k.inspect} キーが存在しないため追加できない"
        end
      end
    end
  end

  class NBTList
    include NBTObjectType

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

    def to_json(...) = @obj.to_json(...)
    def to_enum = @obj.to_enum
    def to_a = @obj
    def hash = [@obj, self.class].hash

    def [](k)
      return nil unless k in Integer
      key = k.to_i
      @obj[key]
    end

    def dig(*path)
      k, *rest = path.flatten
      return nil unless k in Integer
      key = k.to_i
      if rest.empty?
        self[key]
      else
        self[key]&.dig(*rest)
      end
    end

    def cow(path, value)
      k, *rest = path
      raise TypeError, "#{self.class}#cow: キーは Integer (実際に渡したのは #{k.class})" unless k in Integer
      key = k.to_i
      unless (0..@obj.size).include?(key)
        raise KeyError, "#{self.class}#cow: Listsizeは #{@obj.size} (index: #{k.inspect})"
      end
      if rest.empty?
        ary = @obj.dup
        ary[key] = value
        NBTList.new(ary)
      else
        child = @obj[key]
        if child
          ary = @obj.dup
          ary[key] = @obj[key].cow(rest, value)
          NBTList.new(ary)
        else
          raise KeyError, "#{self.class}#cow: #{k.inspect} キーが存在しないため追加できない"
        end
      end
    end
  end

  class NBTString
    include NBTObjectType
    include Comparable

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

    def to_json(...) = @obj.to_json(...)
    def to_s = @obj
    def hash = [@obj, self.class].hash
    def <=>(other) = (other <=> @obj)&.-@
  end

  class Integral
    include NBTObjectType
    include Comparable

    def initialize(obj, bind: nil)
      raise NBTRangeError unless self.class::RANGE.include?(obj)
      @obj = cnv(obj)
    end

    def snbt = "#{@obj}#{self.class::SUFFIX}"
    def to_json(...) = @obj.to_json(...)
    def to_i = @obj.to_i
    def to_f = @obj.to_f
    def hash = [@obj, self.class].hash
    def <=>(other) = (other <=> @obj)&.-@

    private def cnv(a) = a.to_i
  end

  class NBTByte < Integral
    RANGE = -0x80..0x7f
    SUFFIX = 'B'
  end

  class NBTShort < Integral
    RANGE = -0x8000..0x7fff
    SUFFIX = 'S'
  end

  class NBTInteger < Integral
    RANGE = -0x80000000..0x7fffffff
    SUFFIX = ''
  end

  class NBTLong < Integral
    RANGE = -0x8000000000000000..0x7fffffffffffffff
    SUFFIX = 'L'
  end

  class NBTFloat < Integral
    RANGE = -1.7E+308..1.7E+308
    SUFFIX = 'F'
    private def cnv(a) = a.to_f
  end

  # NBTとしてはないっぽいが、JSONとの相互変換のときにByteと区別がつかなくなるので内部的にもっておく
  class NBTBoolean < Integral
    RANGE = [true, false]
    SUFFIX = 'B'
    private def cnv(a) = a ? 1 : 0
  end
end
