describe Fastlane::Actions::DiawiAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The diawi plugin is working!")

      Fastlane::Actions::DiawiAction.run(nil)
    end
  end
end
