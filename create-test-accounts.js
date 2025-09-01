import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing Supabase credentials');
  process.exit(1);
}

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

const testAccounts = [
  {
    email: 'test_client@deegongso.com',
    password: 'test123456',
    role: 'client',
    name: '테스트 클라이언트',
    company: '테스트 회사',
    department: '마케팅팀',
    phone: '010-1111-1111'
  },
  {
    email: 'test_designer@deegongso.com',
    password: 'test123456',
    role: 'designer',
    name: '테스트 디자이너',
    experience: '5년 이상',
    phone: '010-2222-2222'
  },
  {
    email: 'test_admin@deegongso.com',
    password: 'test123456',
    role: 'admin',
    name: '테스트 관리자',
    phone: '010-3333-3333'
  }
];

async function createTestAccounts() {
  console.log('Creating test accounts...');

  for (const account of testAccounts) {
    try {
      console.log(`Creating ${account.role} account: ${account.email}`);
      
      // 1. Supabase Auth에서 사용자 생성
      const { data: authData, error: signUpError } = await supabaseAdmin.auth.admin.createUser({
        email: account.email,
        password: account.password,
        email_confirm: true,
        user_metadata: {
          name: account.name,
          role: account.role
        }
      });

      if (signUpError) {
        if (signUpError.message.includes('already registered')) {
          console.log(`${account.email} already exists, updating profile...`);
          
          // 기존 사용자 찾기
          const { data: users } = await supabaseAdmin.auth.admin.listUsers();
          const existingUser = users.users.find(u => u.email === account.email);
          
          if (existingUser) {
            // 프로필 업데이트
            const { error: updateError } = await supabaseAdmin
              .from('users')
              .upsert({
                id: existingUser.id,
                email: account.email,
                name: account.name,
                role: account.role,
                phone: account.phone,
                company: account.company || null,
                department: account.department || null,
                experience: account.experience || null,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              });

            if (updateError) {
              console.error(`Error updating profile for ${account.email}:`, updateError);
            } else {
              console.log(`✅ ${account.email} profile updated successfully`);
            }
          }
          continue;
        } else {
          throw signUpError;
        }
      }

      if (authData.user) {
        // 2. 프로필 테이블에 사용자 정보 저장
        const { error: profileError } = await supabaseAdmin
          .from('users')
          .insert({
            id: authData.user.id,
            email: account.email,
            name: account.name,
            role: account.role,
            phone: account.phone,
            company: account.company || null,
            department: account.department || null,
            experience: account.experience || null,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (profileError) {
          console.error(`Error creating profile for ${account.email}:`, profileError);
        } else {
          console.log(`✅ ${account.email} created successfully`);
        }
      }
    } catch (error) {
      console.error(`Error creating ${account.email}:`, error);
    }
  }

  console.log('\n테스트 계정 생성 완료!');
  console.log('생성된 계정:');
  testAccounts.forEach(account => {
    console.log(`- ${account.email} (${account.role}) - 비밀번호: ${account.password}`);
  });
}

createTestAccounts().catch(console.error);