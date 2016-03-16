require 'test_helper'

describe NonStupidDigestAssets do
  def generate_mock_file(file_path, logical_path)
    [ file_path, { 'logical_path' => logical_path } ]
  end

  describe '#files' do
    it 'does not alter files if whitelist is empty' do
      NonStupidDigestAssets.whitelist.must_be_empty
      NonStupidDigestAssets.files(%w(file1 file2)).must_equal(%w(file1 file2))
    end

    it 'returns files that match whitelist' do
      matches = [
        generate_mock_file('/1/...', 'file-jazz.png'),
        generate_mock_file('/2/...', 'file-jazz-ab149e2bf.png'),
        generate_mock_file('/3/...', 'tmp-file-jazz.png'),
        generate_mock_file('/4/...', 'file1.js'),
      ]
      mismatches = [
        generate_mock_file('/5/...', 'file-JAZZ.png'),
        generate_mock_file('/6/...', 'file-jazz.js'),
        generate_mock_file('/7/...', '/user/programmer/assets/javascripts/file1.js'),
        generate_mock_file('/8/...', 'file1-png')
      ]
      NonStupidDigestAssets.whitelist = [/file\-jazz.*png/, 'file1.js']
      NonStupidDigestAssets.files(matches + mismatches).must_equal(matches)
    end
  end

  describe NonStupidDigestAssets::CompileWithNonDigest do
    class TestSubject
      include NonStupidDigestAssets::CompileWithNonDigest

      attr_accessor :files, :dir

      def compile(*args)
        return 'super compile return value'
      end
    end

    describe '.compile' do
      it 'copies whitelisted digest files to their logical paths' do
        test_subject = TestSubject.new
        test_subject.files = %w(. .. ...)
        test_subject.dir = '/home/developer/workspace/app/'

        whitelisted_files = [
          [ 'file-jazz-fc447e1a69f5c86d.png', { 'logical_path' => 'file-jazz.png' } ],
          [ 'file-jazz-ab149e2bf-2752fba1fa59bb72.png', { 'logical_path' => 'file-jazz-ab149e2bf.png' } ],
          [ 'tmp-file-jazz-d4c96cd11dae6650.png', { 'logical_path' => 'tmp-file-jazz.png' } ],
          [ 'file1-ff3fee8c6ef27373.js', { 'logical_path' => 'file1.js' } ]
        ]

        NonStupidDigestAssets.expects(:files).with(test_subject.files).returns(whitelisted_files)
        whitelisted_files.each do |digest_path, info|
          full_digest_path = File.join(test_subject.dir, digest_path)
          full_non_digest_path = File.join(test_subject.dir, info['logical_path'])
          full_digest_gz_path = full_digest_path + '.gz'
          full_non_digest_gz_path = full_non_digest_path + '.gz'

          File.expects(:exists?).with(full_digest_path).returns(true)
          FileUtils.expects(:copy_file).with(full_digest_path, full_non_digest_path, :preserve_attributes).returns(nil)
          File.expects(:exists?).with(full_digest_gz_path).returns(true)
          FileUtils.expects(:copy_file).with(full_digest_gz_path, full_non_digest_gz_path, :preserve_attributes).returns(nil)
        end

        test_subject.compile.must_equal('super compile return value')
      end

      it 'gracefully handled non-existing files' do
        test_subject = TestSubject.new
        test_subject.files = %w(. .. ...)
        test_subject.dir = '/home/developer/workspace/app/'

        whitelisted_files = [
          [ 'file-jazz-fc447e1a69f5c86d.png', { 'logical_path' => 'file-jazz.png' } ],
          [ 'file-jazz-ab149e2bf-2752fba1fa59bb72.png', { 'logical_path' => 'file-jazz-ab149e2bf.png' } ]
        ]

        NonStupidDigestAssets.expects(:files).with(test_subject.files).returns(whitelisted_files)
        whitelisted_files.each do |digest_path, info|
          full_digest_path = File.join(test_subject.dir, digest_path)
          full_digest_gz_path = full_digest_path + '.gz'

          File.expects(:exists?).with(full_digest_path).returns(false)
          File.expects(:exists?).with(full_digest_gz_path).returns(false)
          FileUtils.expects(:copy_file).never
        end

        test_subject.compile.must_equal('super compile return value')
      end
    end
  end
end
