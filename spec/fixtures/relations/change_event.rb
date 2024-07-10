module Relations
  class ChangeEvent < Resources::Relations::Adapters::Sql
    use_ar_model ::ChangeEvent
  end
end
