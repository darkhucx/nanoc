module Nanoc::Int
  # Stores checksums for objects in order to be able to detect whether a file
  # has changed since the last site compilation.
  #
  # @api private
  class ChecksumStore < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    attr_accessor :objects

    # @param [Nanoc::Int::Site] site
    def initialize(site: nil, objects:)
      super(Nanoc::Int::Store.tmp_path_for(env_name: (site.config.env_name if site), store_name: 'checksums'), 1)

      @site = site # TODO: Remove
      @objects = objects

      @checksums = {}
    end

    contract C::Any => C::Maybe[String]
    # Returns the old checksum for the given object. This makes sense for
    # items, layouts and code snippets.
    #
    # @param [#reference] obj The object for which to fetch the checksum
    #
    # @return [String] The checksum for the given object
    def [](obj)
      @checksums[obj.reference]
    end

    # Calculates and stores the checksum for the given object.
    def add(obj)
      if obj.is_a?(Nanoc::Int::Document)
        @checksums[[obj.reference, :content]] = Nanoc::Int::Checksummer.calc_for_content_of(obj)
        @checksums[[obj.reference, :attributes]] = Nanoc::Int::Checksummer.calc_for_attributes_of(obj)
      end

      @checksums[obj.reference] = Nanoc::Int::Checksummer.calc(obj)
    end

    contract C::Any => C::Maybe[String]
    def content_checksum_for(obj)
      @checksums[[obj.reference, :content]]
    end

    contract C::Any => C::Maybe[String]
    def attributes_checksum_for(obj)
      @checksums[[obj.reference, :attributes]]
    end

    protected

    def data
      @checksums
    end

    def data=(new_data)
      references = Set.new(@objects.map(&:reference))

      @checksums = {}
      new_data.each_pair do |key, checksum|
        if references.include?(key) || references.include?(key.first)
          @checksums[key] = checksum
        end
      end
    end
  end
end
