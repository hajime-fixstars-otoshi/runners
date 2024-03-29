class GitDiffParser::Patches
  def find_patch_by_file: (String) -> GitDiffParser::Patch?
end

class GitDiffParser::Patch
  def changed_lines: () -> Array<GitDiffParser::Line>
end

class GitDiffParser::Line
  attr_reader number: Integer
end
