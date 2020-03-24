# frozen_string_literal: true

def build_key(schema, **options)
  Digest::SHA1.hexdigest(build_payload(schema, options).to_json)
end

def build_payload(schema, **options)
  query_cache_key = options[:query_cache_key] || {
    path_cache_key: options[:path_cache_key],
    selections_cache_key: options[:selections_cache_key]
  }

  {
    schema_cache_key: schema.schema_cache_key,
    query_cache_key: query_cache_key,
    context_cache_key: options[:context_cache_key]
  }
end

shared_context "check used key" do |options = {}|
  before do
    allow(schema.fragment_cache_store).to receive(:set)
  end

  it "uses expected key" do
    schema.execute(query, variables: variables || {}, context: context || {})

    expect(schema.fragment_cache_store).to \
      have_received(:set) do |used_key, _, passed_options|
        expect(used_key).to eq(key)
        expect(passed_options[:ex]).to eq(options[:ex]) if options[:ex]
      end
  end
end
