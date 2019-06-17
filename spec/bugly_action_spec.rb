describe Fastlane::Actions::BuglyAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The bugly plugin is working!")

      Fastlane::Actions::BuglyAction.run(nil)
    end
  end
end
