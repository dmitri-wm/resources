module Relations
  class Contract < Resources::Relations::Adapters::Sql
    use_ar_model ::Contract
  end
end