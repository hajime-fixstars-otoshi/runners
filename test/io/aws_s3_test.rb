require_relative "../test_helper"

class AwsS3Test < Minitest::Test
  include TestHelper

  def test_parse_s3_uri
    assert_raises(RuntimeError) { Runners::IO::AwsS3.parse_s3_uri!('http://example.com') }
    assert_raises(RuntimeError) { Runners::IO::AwsS3.parse_s3_uri!('s3://bucket') }
    assert_equal ['bucket', 'key'], Runners::IO::AwsS3.parse_s3_uri!('s3://bucket/key')
    assert_equal ['bucket', 'path/to/bar'], Runners::IO::AwsS3.parse_s3_uri!('s3://bucket/path/to/bar')
  end

  def test_write_flush
    mock(Aws::S3::Client).new(retry_limit: is_a(Numeric), retry_base_delay: is_a(Numeric))
    io = Runners::IO::AwsS3.new('s3://bucket_name/object_name')
    io.write('abc')
    io.write('!!!')
    io.flush
    assert_equal 'abc!!!', io.tempfile.tap(&:rewind).read
  end

  def test_finalize
    mock_object = Object.new
    mock(Aws::S3::Client).new(retry_limit: is_a(Numeric), retry_base_delay: is_a(Numeric)) { mock_object }
    mock(mock_object).put_object(bucket: 'bucket_name', key: 'object_name', body: instance_of(Tempfile))
    io = Runners::IO::AwsS3.new('s3://bucket_name/object_name')
    io.finalize!
  end

  private

  def stdout
    @stdout ||= StringIO.new
  end
end