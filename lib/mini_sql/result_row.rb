module MiniSql
  class ResultRow < Array
    attr_reader :decorator_module

    def initialize(decorator_module: nil)
      @decorator_module = decorator_module
    end

    def marshal_dump
      {
          values_rows: map { |row| row.to_h.values },
          fields: self.first.to_h.keys,
          decorator_module: self.decorator_module,
      }
    end

    PgStruct = Struct.new(:fields)

    def marshal_load(values_rows:, fields:, decorator_module:)
      @decorator_module = decorator_module
      materializer = MiniSql::Postgres::DeserializerCache.new_row_matrializer(PgStruct.new(fields))

      materializer.include(decorator_module) if decorator_module

      values_rows.each do |row_result|
        obj = materializer.new
        fields.each_with_index do |f, col|
          obj.instance_variable_set("@#{f}", row_result[col])
        end
        self.push(obj)
      end

      self
    end
  end

end
