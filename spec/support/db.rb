module DbHelpers
  def self.included(klass)
    klass.before do
      db_truncate
    end
  end

  def db_setup(opts={})
    use_time = opts[:use_time]

    DB.drop_table(:room_versions) if DB.table_exists?(:room_versions)
    DB.drop_table(:rooms) if DB.table_exists?(:rooms)
    DB.create_table! :rooms do
      primary_key :id
      Boolean     :disabled, null: false, default: false
    end
    DB.create_table! :room_versions do
      primary_key :id
      foreign_key :master_id, :rooms
      String      :name
      Fixnum      :price
      Fixnum      :length
      Fixnum      :width
      send(use_time ? :Time : :Date, :created_at)
      send(use_time ? :Time : :Date, :expired_at)
      send(use_time ? :Time : :Date, :valid_from)
      send(use_time ? :Time : :Date, :valid_to)
    end
    @version_class = Class.new Sequel::Model do
      set_dataset :room_versions
      def validate
        super
        errors.add(:name, "is required") unless name
        errors.add(:price, "is required") unless price
      end
    end

    bitemporal_options = {version_class: @version_class}
    bitemporal_options[:audit_class] = opts[:audit_class] if opts[:audit_class]
    bitemporal_options[:audit_updated_by_method] = opts[:audit_updated_by_method] if opts[:audit_updated_by_method]

    @master_class = Class.new Sequel::Model do
      set_dataset :rooms
      plugin :bitemporal, bitemporal_options
    end
  end

  def db_truncate
    @version_class.truncate
    @master_class.truncate
  end
end
