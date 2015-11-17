import os

input_folder = 'in/'
output_folder = 'out/'


def convert_folder(folder_path):

	for in_file in os.listdir(folder_path):

		file_path = os.path.join(folder_path, in_file)
		if os.path.isdir(file_path):
			convert_folder(file_path)
		else:
			if in_file.find('.nut') > -1:
				print('Converting ' + file_path)

				with open(file_path) as in_stream:
					squirrel_src = in_stream.readlines()
					#
					# if folder_path != '' and not os.path.exists(folder_path.replace(input_folder, output_folder)):
					# 	os.makedirs(os.path.exists(folder_path.replace(input_folder, output_folder)), exist_ok=True)

					out_stream = open(file_path.replace(input_folder, output_folder).replace('.nut', '.py'), 'w')

					# start parsing
					indent_level = 0
					within_comment = False

					within_class = False
					class_indent_level = -1

					within_function = False
					function_indent_level = -1

					within_if = False
					within_for = False

					members_collected = []

					for current_line in squirrel_src:

						while current_line.startswith('\t'):
							current_line = current_line[1:]
						current_line = current_line.replace('\t', ' ')
						current_line = current_line.replace('\n', '')
						current_line = current_line.replace('\r', '')
						current_line = current_line.replace('    ', ' ')
						current_line = current_line.replace('   ', ' ')
						current_line = current_line.replace('   ', ' ')
						current_line = current_line.replace('  ', ' ')
						current_line = current_line.strip()

						if within_class and not within_function:
							pass

						if current_line.startswith('class'):
							within_class = True
							class_indent_level = indent_level

						if current_line.startswith('function'):
							within_function = True
							function_indent_level = indent_level

						# Read comment
						if current_line.startswith('/*'):
							within_comment = True

						if current_line.startswith('*/'):
							within_comment = False

						# Read indentation
						if current_line.startswith('{'):
							indent_level += 1
							current_line = current_line[1:]

						if current_line.startswith('}'):
							indent_level -= 1
							current_line = current_line[1:]
							if within_class and class_indent_level == indent_level:
								within_class = False

							if within_function and function_indent_level == indent_level:
								within_function = False

						if len(current_line) > 0:
							#  Convert the syntax

							#  ReWrite global assignation
							current_line = current_line.replace(' <- ', ' = ')
							current_line = current_line.replace('<-', ' = ')

							#   ReWrite boolean assignations
							current_line = current_line.replace('true', 'True')
							current_line = current_line.replace('false', 'False')

							#  ReWrite 'function' (or method)
							if current_line.startswith('function '):
								current_line = current_line.replace('function ', 'def ')
								current_line += ':'
								if within_class:
									coma_pos = current_line.find('(')
									if coma_pos > -1:
										coma_pos += 1
										current_line = current_line[:coma_pos] + 's, ' + current_line[coma_pos:]

							#  ReWrite 'if'
							if current_line.startswith('if '):
								current_line += ':'

							# ReWrite comment
							if within_comment or current_line.startswith('//') or current_line.startswith('/*') or current_line.startswith('*/'):
								current_line = '# ' + current_line[2:]

							current_line = current_line.replace('//', '# ')

							current_line = ('\t' * indent_level) + current_line
							current_line += '\n'

							if current_line.replace('\t', '').startswith('def '):
								current_line = '\n' + current_line

							out_stream.write(current_line)

				out_stream.close()
				in_stream.close()

convert_folder(input_folder)

