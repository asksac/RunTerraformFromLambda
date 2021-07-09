import sys, os, os.path, time
import logging
import subprocess

# lambda_root = os.getenv('LAMBDA_TASK_ROOT', os.path.dirname(__file__))
base_dir = os.path.dirname(__file__)
sys.path.append(base_dir + '/bin')
tf_root = os.path.join(base_dir, 'terraform')

root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)
logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',level=logging.INFO)

def lambda_handler(event, context):

  '''
  # logging for debugging purposes only
  logging.debug('base_dir = ' + base_dir)
  logging.debug('tf_root = ' + tf_root)
  logging.debug('sys.path = ' + str(sys.path))

  for k, v in sorted(os.environ.items()):
    logging.debug(str(k) + ':' + str(v))
  '''

  init_command = './bin/terraform -chdir=%s init -input=false' % (tf_root)
  apply_command = './bin/terraform -chdir=%s apply -input=false -auto-approve' % (tf_root)

  command = init_command + '; ' + apply_command

  output = ''; 
  start_time = time.time()

  # execute terraform command 
  logging.info('starting terraform command execution: %s' % command)
  proc = subprocess.Popen(command, shell=True, text=True, stdout=subprocess.PIPE, stderr=sys.stdout.buffer)
  logging.info('launched process has id %s' % proc.pid)
  while True: 
    lineout = proc.stdout.readline()
    output += lineout
    if lineout:
      logging.info(lineout.strip())
    if proc.poll() is not None:
      break
  # terraform execution ends
  end_time = time.time()
  exec_time = end_time - start_time

  rc = proc.returncode
  logging.info('terraform command completed with return code %s' % rc)

  if rc == 0: 
    status_code = 200
  else: 
    status_code = 500

  return {
    'statusCode': status_code,
    'body': {
      'returnCode': rc, 
      'executionTime': exec_time, 
      'output': output
    }
  }

# if called from terminal 
if __name__ == '__main__':
  print(lambda_handler(None, None))