describe Fastlane do

  describe Fastlane::Actions::ZipAction do
    describe "zip" do
      it "sets default values for optional include and exclude parameters" do
        params = { path: "Test.app" }
        action = Fastlane::Actions::ZipAction::Runner.new(params)

        expect(action.include).to eq([])
        expect(action.exclude).to eq([])
      end
    end
  end

  describe Fastlane::FastFile do
    before do
      allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
      @fixtures_path = "./fastlane/spec/fixtures/actions/zip"
      @path = @fixtures_path + "/file.txt"
      @output_path_with_zip = @fixtures_path + "/archive_file.zip"
      @output_path_without_zip = @fixtures_path + "/archive_file"
    end

    describe "zip" do
      it "generates a valid zip command" do
        expect(Fastlane::Actions).to receive(:sh).with("zip", "-r", "#{File.expand_path(@path)}.zip", "file.txt")

        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@path}')
        end").runner.execute(:test)
      end

      it "generates a valid zip command without verbose output" do
        expect(Fastlane::Actions).to receive(:sh).with("zip", "-rq", "#{File.expand_path(@path)}.zip", "file.txt")

        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@path}', verbose: false)
        end").runner.execute(:test)
      end

      it "generates an output path given no output path" do
        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@path}', output_path: '#{@path}')
        end").runner.execute(:test)

        expect(result).to eq(File.absolute_path("#{@path}.zip"))
      end

      it "generates an output path with zip extension (given zip extension)" do
        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@path}', output_path: '#{@output_path_with_zip}')
        end").runner.execute(:test)

        expect(result).to eq(File.absolute_path(@output_path_with_zip))
      end

      it "generates an output path with zip extension (not given zip extension)" do
        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@path}', output_path: '#{@output_path_without_zip}')
        end").runner.execute(:test)

        expect(result).to eq(File.absolute_path(@output_path_with_zip))
      end

      it "encrypts the contents of the zip archive using a password" do
        password = "5O#RUKp0Zgop"
        expect(Fastlane::Actions).to receive(:sh).with("zip", "-rq", "-P", password, "#{File.expand_path(@path)}.zip", "file.txt")

        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@path}', verbose: false, password: '#{password}')
        end").runner.execute(:test)
      end

      it "archives a directory" do
        expect(Fastlane::Actions).to receive(:sh).with("zip", "-r", "#{File.expand_path(@fixtures_path)}.zip", "zip")

        result = Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@fixtures_path}')
        end").runner.execute(:test)
      end

      it "invokes Actions.sh in a way which escapes arguments" do
        path_basename = "My Folder (New)"
        path = File.expand_path(File.join(@fixtures_path, path_basename))
        output_path = File.expand_path(File.join(@fixtures_path, "My Folder (New).zip"))
        password = "#Test Password"
        exclude_pattern = path_basename + "/**/*.md"

        expect(Fastlane::Actions).to receive(:sh).with('zip', '-r', '-P', password, output_path, path_basename, '-x', exclude_pattern).and_call_original

        # With sh_helper, this is the best way to check the **escaped** shell output is to check the command it prints.
        # Actions.sh will only escape inputs in some conditions, and its tricky to make sure that it was invoked in a way that did escape it.
        expect(Fastlane::UI).to receive(:command).with("zip -r -P #{password.shellescape} #{output_path.shellescape} #{path_basename.shellescape} -x #{exclude_pattern.shellescape}")

        Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{path}', output_path: '#{output_path}', password: '#{password}', exclude: ['**/*.md'])
        end").runner.execute(:test)
      end

      it "supports excluding specific files or directories" do
        expect(Fastlane::Actions).to receive(:sh).with("zip", "-r", "#{File.expand_path(@fixtures_path)}.zip", "zip", "-x", "zip/.git/*", "zip/README.md")

        Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@fixtures_path}', exclude: ['.git/*', 'README.md'])
        end").runner.execute(:test)
      end

      it "supports including specific files or directories" do
        expect(Fastlane::Actions).to receive(:sh).with("zip", "-r", "#{File.expand_path(@fixtures_path)}.zip", "zip", "-i", "zip/**/*.rb")

        Fastlane::FastFile.new.parse("lane :test do
          zip(path: '#{@fixtures_path}', include: ['**/*.rb'])
        end").runner.execute(:test)
      end
    end
  end
end
