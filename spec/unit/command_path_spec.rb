# encoding: utf-8

RSpec.describe TTY::Editor, '#command' do
  it 'escapes editor filename on Unix' do
    editor = TTY::Editor.new("/usr/bin/hello world.rb")
    allow(TTY::Editor).to receive(:command).and_return('vim')
    allow(editor).to receive(:windows?).and_return(false)

    expect(editor.command_path).to eql("vim /usr/bin/hello\\ world.rb")
  end

  it "escapes path separators on Windows" do
    editor = TTY::Editor.new('C:\User\hello world.rb')
    allow(TTY::Editor).to receive(:command).and_return('vim')
    allow(editor).to receive(:windows?).and_return(true)

    expect(editor.command_path).to eql("vim C:\\User\\hello world.rb")
  end
end
