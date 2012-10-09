require 'flatpack_core'

class Merchant < Flatpack::Core::BaseHasUuid
  attr_accessor :uuid, :merchant_locations;
end

class StreetAddress < Flatpack::Core::BaseHasUuid
  PROPERTY_NAMES = [:address, :city, :state, :zip]
  attr_accessor *PROPERTY_NAMES
end

class MerchantLocation < Flatpack::Core::BaseHasUuid
  PROPERTY_NAMES = [:uuid, :merchant]
  attr_accessor *PROPERTY_NAMES

  EMBEDDED_PROPERTY_NAMES = [
      :street_address
  ]
  attr_accessor *EMBEDDED_PROPERTY_NAMES

  TYPE_MAP = {
      :street_address => StreetAddress,
  }
end

class TestEntity < Flatpack::Core::BaseHasUuid
  PROPERTY_NAMES = [
      :one,
      :two,
      :test_sub_entities,
      :test_entities,
      :test_entity
  ]
  attr_accessor *PROPERTY_NAMES
end

class TestSubEntity < TestEntity
  PROPERTY_NAMES = [
      :three
  ]
  attr_accessor *PROPERTY_NAMES
end

describe Flatpack::Core do

  before(:all) do
    @flatpack = Flatpack::Core::Flatpack.new({
                                                 :pretty => true,
                                                 :verbose => true
                                             })
  end

  it "serializes a simple entity" do

    root = TestEntity.new({
                              :one => 'first',
                              :two => 'second'
                          })

    json = @flatpack.packer.pack(root)

    map = JSON.parse(json)
    map['data'].keys.length.should eq(1)
    entities = map['data']['testEntity']
    entities.length.should eq(1)
    entity = entities[0]

    entity.keys.length.should eq(3)
    entity['one'].should eq('first')
    entity['two'].should eq('second')
    entity['uuid'].should be_true
  end

  it "serializes an entity with forward references" do

    root = TestEntity.new({
                              :one => 'first',
                              :two => [
                                  TestSubEntity.new({:one => 'first', :three => 'third'}),
                                  TestSubEntity.new({:one => 'first', :three => 'third'})
                              ]
                          })

    json = @flatpack.packer.pack(root)

    map = JSON.parse(json)

    map['data'].keys.length.should eq(2)

    # we should have 1 TestEntity at our root
    root_entities = map['data']['testEntity']
    root_entities.length.should eq(1)
    root_entity = root_entities[0]
    root_entity['one'].should eq('first')

    # our collection reference at :two should have been flattened away
    root_entity['two'].should be_nil
    root_entity_uuid = root_entity['uuid']

    # two TestSubEntities under our root
    sub_entities = map['data']['testSubEntity']
    sub_entities.length.should eq(2)
    sub_entity_one = sub_entities[0]
    sub_entity_two = sub_entities[1]

    # sub entities should have a reference to the parent
    sub_entity_one['testEntityUuid'].should eq(root_entity_uuid)
    sub_entity_two['testEntityUuid'].should eq(root_entity_uuid)

    # and 3 additional properties
    sub_entity_one.length.should eq(4)
    sub_entity_one['one'].should eq('first')
    sub_entity_one['three'].should eq('third')
    sub_entity_one['two'].should be_nil

    sub_entity_two.length.should eq(4)
    sub_entity_two['one'].should eq('first')
    sub_entity_two['three'].should eq('third')
    sub_entity_two['two'].should be_nil
  end

  it "serializes an entity with back reference" do

    sibling_one = TestEntity.new({
                                     :one => 'first_sibling'
                                 })

    sibling_two = TestEntity.new({
                                     :one => 'second_sibling',
                                     :two => sibling_one
                                 })

    json = @flatpack.packer.pack(sibling_two)

    map = JSON.parse(json)

    map['data'].keys.length.should eq(1)
    entities = map['data']['testEntity']
    entities.each do |e|
      if(e['uuid'].eql?(sibling_one.uuid.to_s))
        e['testEntityUuid'].should eq(sibling_two.uuid.to_s)
      else
        e['testEntityUuid'].should be_nil
      end
    end

  end

  it "de-serializes a simple entity" do

    json = '{'\
      '"value": "b2197fc8-42df-4d8c-9890-0f37a4f99fc7",'\
      '"data": {'\
        '"unknownEntity": [{"uuid":"b2197fc8-42df-4d8c-9890-0f37a4f998ae"}],'\
        '"testEntity": ['\
          '{'\
            '"one": "first",'\
            '"two": "second",'\
            '"uuid": "b2197fc8-42df-4d8c-9890-0f37a4f99fc7"'\
          '}'\
       ']'\
      '}'\
    '}'

    # the unpacking should succeed even when an unknown
    # entity type (unknownEntity) is present
    entity = @flatpack.unpacker.unpack(JSON.parse(json))

    entity.one.should eq('first')
    entity.two.should eq('second')
    entity.uuid.should eq('b2197fc8-42df-4d8c-9890-0f37a4f99fc7')

  end

  it "de-serializes an entity with a collection reference" do
    json = '{'\
      '"value": "d1c958ba-e6ea-4b12-8335-347289e404ac",'\
      '"data": {'\
        '"testEntity": ['\
          '{'\
            '"uuid": "d1c958ba-e6ea-4b12-8335-347289e404ac",'\
            '"one": "first"'\
          '}'\
        '],'\
        '"testSubEntity": ['\
          '{'\
            '"three": "third",'\
            '"uuid": "ae90cb47-5638-4529-9223-049ec89b6162",'\
            '"testEntityUuid": "d1c958ba-e6ea-4b12-8335-347289e404ac",'\
            '"one": "first"'\
          '},'\
          '{'\
            '"three": "third",'\
            '"uuid": "4f00da0c-6427-4d87-b691-bedad45329d7",'\
            '"testEntityUuid": "d1c958ba-e6ea-4b12-8335-347289e404ac",'\
            '"one": "first"'\
          '}'\
        ']'\
      '}'\
    '}'\

    entity = @flatpack.unpacker.unpack(JSON.parse(json))

    entity.uuid.should eq('d1c958ba-e6ea-4b12-8335-347289e404ac')
    entity.one.should eq('first')

    # entity should have both sub entities within the test_entities property
    entity.test_sub_entities.length.should eq(2)
    entity.test_sub_entities[0].three.should eq('third')
    entity.test_sub_entities[0].one.should eq('first')
    entity.test_sub_entities[1].three.should eq('third')
    entity.test_sub_entities[1].one.should eq('first')

    entity.test_sub_entities[0].test_entity.uuid.should eq('d1c958ba-e6ea-4b12-8335-347289e404ac')
  end

  it "deserializes a complex object graph" do
    json = File.open("#{File.dirname(__FILE__)}/merchant.json", "r").read
    merchant = @flatpack.unpacker.unpack(JSON.parse(json))

    # ensure we have the proper number of merchant locations
    merchant.merchant_locations.size.should eq(4)

    # with the proper uuids...

    merchant.merchant_locations.detect do |ml|
      ml.uuid == 'e988f216-aca6-490d-ad45-4840e05da352'
    end.should_not be_nil

    merchant.merchant_locations.detect do |ml|
      ml.uuid == '08ab924a-9742-4e9b-8444-ffc9b43f8566'
    end.should_not be_nil

    merchant.merchant_locations.detect do |ml|
      ml.uuid == 'f77333aa-a66c-4944-9b95-53efc3657418'
    end.should_not be_nil

    merchant.merchant_locations.detect do |ml|
      ml.uuid == '5f72a832-02af-4dd9-8b30-7cef87f37833'
    end.should_not be_nil
  end

  it "tests embeddable properties" do
    json = File.open("#{File.dirname(__FILE__)}/merchant_location.json", "r").read
    location = @flatpack.unpacker.unpack(JSON.parse(json))

    # no address information should be available directly on the location entity
    location.respond_to?(:address).should be_false
    location.respond_to?(:city).should be_false
    location.respond_to?(:state).should be_false
    location.respond_to?(:zip).should be_false

    # instead, they should be within an embedded StreetAddress property
    location.street_address.address.should eq("1 Embarcadero Center")
    location.street_address.city.should eq("San Francisco")
    location.street_address.state.should eq("CA")
    location.street_address.zip.should eq("94111")

    # now we'll pack our location back to JSON, which should fold the
    # embedded address properties onto the location directly, then unpack
    # that JSON again to ensure that the address information has been preserved
    location = @flatpack.unpacker.unpack(JSON.parse(@flatpack.packer.pack(location)))
    location.street_address.address.should eq("1 Embarcadero Center")
    location.street_address.city.should eq("San Francisco")
    location.street_address.state.should eq("CA")
    location.street_address.zip.should eq("94111")

  end

end
